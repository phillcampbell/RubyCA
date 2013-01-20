if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

module RubyCA
  module Core
    module Web

        class Server < Sinatra::Base
          use Rack::MethodOverride
          enable :sessions
          register Sinatra::Flash
          set :bind, CONFIG['web']['host']
          set :port, CONFIG['web']['port']
          set :haml, layout: :layout
          mime_type :pem, 'pem/pem'
        
          before '/admin*' do
            unless CONFIG['web']['admin']['allowed_ips'].include? request.ip
              halt 401, '401 Unauthorised'
            end
          end
          
          get '/ca.crl' do
            @crl = OpenSSL::X509::CRL.new RubyCA::Core::Models::CRL.get(1).crl
            content_type :crl
            @crl.to_der
          end
          
          get '/admin' do
            haml :admin
          end
        
          get '/admin/csrs' do
            @csrs = RubyCA::Core::Models::CSR.all
            haml :csrs
          end
          
          post '/admin/csrs' do
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
          
          delete '/admin/csrs/:cn' do
            @csr = RubyCA::Core::Models::CSR.get(params[:cn])
            @csr.destroy
            redirect '/admin/csrs'
          end
          
          get '/admin/csrs/:cn/sign' do
            @csr = RubyCA::Core::Models::CSR.get(params[:cn])
            haml :sign
          end
        
          post '/admin/csrs/:cn/sign' do
            if RubyCA::Core::Models::Certificate.get(params[:cn])
              flash.next[:error] = "A certificate already exists for '#{params[:cn]}', revoke the old certificate before signing this request"
              redirect '/admin/csrs'
            end
            @csr = RubyCA::Core::Models::CSR.get(params[:cn])
            @crt = RubyCA::Core::Models::Certificate.create( cn: @csr.cn, pkey: @csr.pkey )
            crt_key = OpenSSL::PKey::RSA.new @csr.pkey, params[:passphrase][:certificate]
            @intermediate = RubyCA::Core::Models::Certificate.get(CONFIG['ca']['intermediate']['cn'])
            intermediate_key = OpenSSL::PKey::RSA.new @intermediate.pkey, params[:passphrase][:intermediate]
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
            crt.add_extension crt_ef.create_extension 'keyUsage','digitalSignature', true
            crt.add_extension crt_ef.create_extension 'subjectKeyIdentifier','hash', false
            crt.add_extension crt_ef.create_extension 'crlDistributionPoints', "URI:http://#{CONFIG['web']['domain']}/ca.crl"
            crt.sign intermediate_key, OpenSSL::Digest::SHA512.new
            @crt.crt = crt.to_pem
            @crt.save
            @csr.destroy
            intermediate_key = nil
            flash.next[:success] = "Created certificate for '#{@crt.cn}'"
            redirect '/admin/certificates'
          end
          
          get '/admin/certificates' do
            @certificates = RubyCA::Core::Models::Certificate.all
            haml :certificates
          end
          
          get '/admin/certificates/:cn.crt' do
            @crt = RubyCA::Core::Models::Certificate.get(params[:cn])
            content_type :crt
            @crt.crt
          end
          
          get '/admin/certificates/:cn.pem' do
            @crt = RubyCA::Core::Models::Certificate.get(params[:cn])
            content_type :pem
            @crt.pkey
          end
          
          get '/admin/certificates/:cn/revoke' do
            @crt = RubyCA::Core::Models::Certificate.get(params[:cn])
            haml :revoke
          end
          
          delete '/admin/certificates/:cn/revoke' do
            @crt = RubyCA::Core::Models::Certificate.get(params[:cn])
            if @crt.cn == CONFIG['ca']['root']['cn'] or CONFIG['ca']['intermediate']['cn']
              flash.next[:error] = "Cannot revoke the root or intermediate certificates"
              redirect '/admin/certificates'
            end
            crt = OpenSSL::X509::Certificate.new RubyCA::Core::Models::Certificate.get(@crt.cn).crt
            revoked = OpenSSL::X509::Revoked.new
            revoked.serial = crt.serial
            revoked.time = Time.now
            @intermediate = RubyCA::Core::Models::Certificate.get(CONFIG['ca']['intermediate']['cn'])
            intermediate_key = OpenSSL::PKey::RSA.new @intermediate.pkey, params[:passphrase][:intermediate]
            @crl = RubyCA::Core::Models::CRL.get(1)
            crl = OpenSSL::X509::CRL.new @crl.crl
            crl.add_revoked revoked
            crl.last_update = Time.now
            crl.next_update = Time.now + 60 * 60 * 24 * 30
            crl.sign intermediate_key, OpenSSL::Digest::SHA512.new
            intermediate_key = nil
            @crl.crl = crl.to_pem
            @crl.save
            @crt.destroy
            flash.next[:success] = "Revoked certificate for '#{@crt.cn}'"
            redirect '/admin/certificates'
          end

      end
    end
  end
end