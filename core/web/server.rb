if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

module RubyCA
  module Core
    module Web

        class Server < Sinatra::Base
          use Rack::MethodOverride
          use Rack::Session::Pool
          #enable :sessions
          register Sinatra::Flash
          set :bind, CONFIG['web']['interface']
          set :port, CONFIG['web']['port']
          set :haml, layout: :layout
          mime_type :pem, 'pem/pem'
          
          keyusages = {
            'digitalSignature' => true,
            'dataEncipherment' => false,
            'keyEncipherment' => false,
            'keyAgreement' => false,
            'dataEncipherment' => false,
            'cRLSign' => false
          }
          extendedkeys = { 
            'clientAuth' => false,
            'serverAuth' => false,
            'emailProtection' => false
          }
          
          helpers do
            def protected!
              unless authorized?
                response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
                throw(:halt, [401, "Not authorized\n"])
              end
            end

            def authorized?
              @auth ||=  Rack::Auth::Basic::Request.new(request.env)
              @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [CONFIG['auth']['username'], CONFIG['auth']['password']]
            end
          end
                    
          before '/admin*' do
            unless CONFIG['web']['admin']['allowed_ips'].include? request.ip
              protected!
            end
          end
          
          get '/' do
            redirect '/admin'
          end
          
          get '/ca.crl' do
            @crl = OpenSSL::X509::CRL.new RubyCA::Core::Models::CRL.get(1).crl
            content_type :crl
            @crl.to_der
          end
          
          get '/admin/?' do
            haml :admin
          end
        
          get '/admin/csrs/?' do
            @csrs = RubyCA::Core::Models::CSR.all
            @csr = session[:csr]
            haml :csrs
          end
          
          post '/admin/csrs/?' do            
            params[:csr].each do |k,v|
              if v.nil? || v.empty?
                session[:csr] = params[:csr]
                flash.next[:error] = "All fields are required"
                redirect '/admin/csrs'
              end  
            end
            session[:csr] = nil

            if RubyCA::Core::Models::CSR.get(params[:csr][:cn])
              flash.next[:error] = "A certificate signing request already exists for '#{params[:csr][:cn]}'"
              redirect '/admin/csrs'
            end
            
            @csr = RubyCA::Core::Models::CSR.create(
                cn: params[:csr][:cn],
                o: params[:csr][:o],
                l: params[:csr][:l],
                st: params[:csr][:st],
                c: params[:csr][:c] )
                
            cipher = OpenSSL::Cipher::Cipher.new 'AES-256-CBC'
            key = OpenSSL::PKey::RSA.new 2048
            @csr.pkey = key.export(cipher, params[:csr][:passphrase])
            csr = OpenSSL::X509::Request.new
            csr.version = 2
            csr.subject = OpenSSL::X509::Name.parse "C=#{@csr.c}/ST=#{@csr.st}/L=#{@csr.l}/O=#{@csr.o}/CN=#{@csr.cn}"
            csr.public_key = key.public_key
            csr.sign key, OpenSSL::Digest::SHA512.new
            @csr.csr = csr.to_pem
            @csr.save
            flash.next[:success] = "Created certificate signing request for '#{@csr.cn}'"
            redirect '/admin/csrs'
          end
          
          delete '/admin/csrs/:cn/?' do
            @csr = RubyCA::Core::Models::CSR.get(params[:cn])
            @csr.destroy
            flash.next[:success] = "Deleted certificate signing request for '#{@csr.cn}'"
            redirect '/admin/csrs'
          end
          
          get '/admin/csrs/:cn/sign/?' do            
            if RubyCA::Core::Models::Certificate.get(params[:cn])
              flash.next[:error] = "A certificate already exists for '#{params[:cn]}', revoke the old certificate before signing this request"
              redirect '/admin/csrs'
            end
            @csr = RubyCA::Core::Models::CSR.get(params[:cn])
            haml :sign, :locals => {:keyusages => keyusages, :extendedkeys => extendedkeys}
          end          
                              
          post '/admin/csrs/:cn/sign/?' do
            if RubyCA::Core::Models::Certificate.get(params[:cn])
              flash.next[:error] = "A certificate already exists for '#{params[:cn]}', revoke the old certificate before signing this request"
              redirect '/admin/csrs'
            end
            @csr = RubyCA::Core::Models::CSR.get(params[:cn])
            begin
              crt_key = OpenSSL::PKey::RSA.new @csr.pkey, params[:passphrase][:certificate]
            rescue OpenSSL::PKey::RSAError
              flash.next[:error] = "Incorrect certificate passphrase"
              redirect "/admin/csrs/#{params[:cn]}/sign"
            end
            @intermediate = RubyCA::Core::Models::Certificate.get(CONFIG['ca']['intermediate']['cn'])
            begin
              intermediate_key = OpenSSL::PKey::RSA.new @intermediate.pkey, params[:passphrase][:intermediate]
            rescue OpenSSL::PKey::RSAError
              flash.next[:error] = "Incorrect intermediate passphrase"
              redirect "/admin/csrs/#{params[:cn]}/sign"
            end
            @crt = RubyCA::Core::Models::Certificate.create( cn: @csr.cn, pkey: @csr.pkey )
            csr = OpenSSL::X509::Request.new @csr.csr
            intermediate_crt = OpenSSL::X509::Certificate.new @intermediate.crt
            crt = OpenSSL::X509::Certificate.new
            @serial = RubyCA::Core::Models::Config.get('last_serial')
            crt.serial = @serial.value.to_i + 1
            @serial.value = crt.serial.to_s
            @serial.save
            crt.version = 2
            crt.not_before = Time.utc(Time.now.year, Time.now.month, Time.now.day, 00, 00, 0)
            crt.not_after = crt.not_before  + (CONFIG['certificate']['years'] * 365 * 24 * 60 * 60 - 1) + ((CONFIG['certificate']['years'] / 4).to_int * 24 * 60 * 60)
            crt.subject = csr.subject
            crt.public_key = csr.public_key
            crt.issuer = intermediate_crt.subject
            crt_ef = OpenSSL::X509::ExtensionFactory.new
            crt_ef.subject_certificate = crt
            crt_ef.issuer_certificate = intermediate_crt
            crt.add_extension crt_ef.create_extension 'subjectKeyIdentifier','hash', false
            altnames = params[:subjectAltName].reject{|k,v| v.empty?}
            crt.add_extension crt_ef.create_extension 'subjectAltName',"#{altnames.map{|san,v| "#{san}:#{v}"}.join(',')}" unless altnames.empty? 
            crt.add_extension crt_ef.create_extension 'keyUsage',params[:keyusage].nil? ? "digitalSignature" : "#{params[:keyusage].map{|ku,v| "#{ku}"}.join(',')}", true
            crt.add_extension crt_ef.create_extension 'extendedKeyUsage',"#{params[:extendedkey].map{|ek,v| "#{ek}"}.join(',')}" unless params[:extendedkey].nil?
            
            crldist = "URI:http://#{CONFIG['web']['domain']}#{(':' + CONFIG['web']['port'].to_s) unless CONFIG['web']['port'] == 80}/ca.crl"
            unless CONFIG['altcrl'].nil? || CONFIG['altcrl']['uri'].nil? || CONFIG['altcrl']['uri'] ===''
              crldist = "#{crldist},URI:#{CONFIG['altcrl']['uri']}"
            end
            crt.add_extension crt_ef.create_extension 'crlDistributionPoints', "#{crldist}"
            
            crt.sign intermediate_key, OpenSSL::Digest::SHA512.new
            @crt.crt = crt.to_pem
            @crt.save
            @csr.destroy
            intermediate_key = nil
            flash.next[:success] = "Created certificate for '#{@crt.cn}'"
            redirect '/admin/certificates'
          end
          
          get '/admin/certificates/?' do
            @certificates = RubyCA::Core::Models::Certificate.all
            @revokeds = RubyCA::Core::Models::Revoked.all
            haml :certificates
          end
          
          get '/admin/certificates/:cn.crt' do
            @crt = RubyCA::Core::Models::Certificate.get(params[:cn])
            content_type :crt
            @crt.crt
          end
          
          get '/admin/certificates/chain/:cn.crt' do
            output = RubyCA::Core::Models::Certificate.get(params[:cn]).crt
            unless params[:cn] === CONFIG['ca']['root']['cn'] or params[:cn] === CONFIG['ca']['intermediate']['cn']
              output << RubyCA::Core::Models::Certificate.get(CONFIG['ca']['intermediate']['cn']).crt
            end
            unless params[:cn] === CONFIG['ca']['root']['cn']
              output << RubyCA::Core::Models::Certificate.get(CONFIG['ca']['root']['cn']).crt
            end
            content_type :crt
            output
          end
          
          get '/admin/certificates/:cn.pem' do
            @crt = RubyCA::Core::Models::Certificate.get(params[:cn])
            content_type :pem
            @crt.pkey
          end
          
          get '/admin/certificates/decrypted/:cn.pem' do
            @crt = RubyCA::Core::Models::Certificate.get(params[:cn])
            if @crt.cn === CONFIG['ca']['root']['cn'] or @crt.cn === CONFIG['ca']['intermediate']['cn']
              flash.next[:error] = "Root or intermediate decrypted private key are disabled"
              redirect '/admin/certificates'
            else
              haml :rsadecrypt
            end
          end
          
          post '/admin/certificates/decrypted/:cn.pem' do   
            @crt = RubyCA::Core::Models::Certificate.get(params[:cn])
            if @crt.cn === CONFIG['ca']['root']['cn'] or @crt.cn === CONFIG['ca']['intermediate']['cn']
              flash.next[:error] = "Root or intermediate decrypted private key are disabled"
              redirect '/admin/certificates'
            else
              begin
                deckey = OpenSSL::PKey::RSA.new @crt.pkey, params[:passphrase][:certificate]
                content_type :pem
                deckey.to_pem
              rescue OpenSSL::PKey::RSAError
                flash.next[:error] = "Incorrect certificate passphrase"
                redirect "/admin/certificates/#{params[:cn]}.p12"
              end
            end
          end

          get '/admin/certificates/:cn.p12' do
            @crt = RubyCA::Core::Models::Certificate.get(params[:cn])
            if @crt.cn === CONFIG['ca']['root']['cn'] or @crt.cn === CONFIG['ca']['intermediate']['cn']
              flash.next[:error] = "Root or intermediate pkcs12 certificates are disabled"
              redirect '/admin/certificates'
            else
              haml :pkcs12
            end
          end
          
          post '/admin/certificates/:cn.p12' do
            @crt = RubyCA::Core::Models::Certificate.get(params[:cn])
            rawCA = RubyCA::Core::Models::Certificate.get(CONFIG['ca']['root']['cn']).crt
            rawintCA = RubyCA::Core::Models::Certificate.get(CONFIG['ca']['intermediate']['cn']).crt
            root_ca = OpenSSL::X509::Certificate.new rawCA
            root_int_ca = OpenSSL::X509::Certificate.new rawintCA
            
            if @crt.cn === CONFIG['ca']['root']['cn'] or @crt.cn === CONFIG['ca']['intermediate']['cn']
              flash.next[:error] = "Root or intermediate pkcs12 certificates are disabled"
              redirect '/admin/certificates'
            else
              raw = @crt.crt
              cert = OpenSSL::X509::Certificate.new raw
              begin
                deckey = OpenSSL::PKey::RSA.new @crt.pkey, params[:passphrase][:certificate]
              rescue OpenSSL::PKey::RSAError
                flash.next[:error] = "Incorrect certificate passphrase"
                redirect "/admin/certificates/#{params[:cn]}.p12"
              end
              
              begin
                p12 = OpenSSL::PKCS12.create(params[:passphrase][:certificate], params[:cn], deckey, cert, [root_ca, root_int_ca])
                content_type :p12
                p12.to_der
              rescue OpenSSL::PKCS12::PKCS12Error
                flash.next[:error] = "Error in pkcs12 generate"
                redirect "/admin/certificates/#{params[:cn]}.p12"
              end
              #redirect "/admin/certificates"
            end
          end
          
          get '/admin/certificates/:cn/revoke/?' do
            @crt = RubyCA::Core::Models::Certificate.get(params[:cn])
            if @crt.cn === CONFIG['ca']['root']['cn'] or @crt.cn === CONFIG['ca']['intermediate']['cn']
              flash.next[:error] = "Cannot revoke the root or intermediate certificates"
              redirect '/admin/certificates'
            end
            haml :revoke
          end
          
          delete '/admin/certificates/:cn/revoke/?' do
            @crt = RubyCA::Core::Models::Certificate.get(params[:cn])
            if @crt.cn === CONFIG['ca']['root']['cn'] or @crt.cn === CONFIG['ca']['intermediate']['cn']
              flash.next[:error] = "Cannot revoke the root or intermediate certificates"
              redirect '/admin/certificates'
            end
            crt = OpenSSL::X509::Certificate.new RubyCA::Core::Models::Certificate.get(@crt.cn).crt
            revoked = OpenSSL::X509::Revoked.new
            revoked.serial = crt.serial
            revoked.time = Time.now
            @intermediate = RubyCA::Core::Models::Certificate.get(CONFIG['ca']['intermediate']['cn'])
            begin
              intermediate_key = OpenSSL::PKey::RSA.new @intermediate.pkey, params[:passphrase][:intermediate]
            rescue OpenSSL::PKey::RSAError
              flash.next[:error] = "Incorrect intermediate passphrase"
              redirect "/admin/certificates/#{params[:cn]}/revoke"
            end
            @crl = RubyCA::Core::Models::CRL.get(1)
            crl = OpenSSL::X509::CRL.new @crl.crl
            crl.add_revoked revoked
            crl.last_update = Time.now
            crl.next_update = Time.now + 60 * 60 * 24 * 30
            crl.sign intermediate_key, OpenSSL::Digest::SHA512.new
            intermediate_key = nil
            @crl.crl = crl.to_pem
            @crl.save
            @revokedcert = RubyCA::Core::Models::Revoked.create( cn: @crt.cn, pkey: @crt.pkey, crt: @crt.crt )
            @revokedcert.save
            @crt.destroy
            flash.next[:success] = "Revoked certificate for '#{@crt.cn}'"
            redirect '/admin/certificates'
          end
          
          delete '/admin/revokeds/:id/?' do
            @revokedcert = RubyCA::Core::Models::Revoked.get(params[:id])
            @revokedcert.destroy
            flash.next[:success] = "Removed revoked certificate for '#{@revokedcert.id}: #{@revokedcert.cn}'"
            redirect '/admin/certificates'
          end
      end
    end
  end
end
