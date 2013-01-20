module RubyCA
  module Core
    module Web

        class Server < Sinatra::Base
          use Rack::MethodOverride
          set :bind, CONFIG['web']['host']
          set :port, CONFIG['web']['port']
          set :haml, layout: :layout
        
          before '/admin*' do
            unless CONFIG['web']['admin']['allowed_ips'].include? request.ip
              halt 401, '401 Unauthorised'
            end
          end
        
          get '/admin/csr' do
            @csrs = RubyCA::Core::Models::CSR.all
            haml :csr
          end
          
          post '/admin/csr' do
            @csr = RubyCA::Core::Models::CSR.create(
                cn: params[:csr][:cn],
                o: params[:csr][:o],
                l: params[:csr][:l],
                st: params[:csr][:st],
                c: params[:csr][:c] )
            cipher = OpenSSL::Cipher::Cipher.new 'AES-256-CBC'
            key = OpenSSL::PKey::RSA.new 2048
            open $root_dir + "/keys/#{@csr.id}-#{@csr.cn}.pem", 'w' do |io|
              io.write key.export(cipher, params[:csr][:passphrase])
            end
            csr = OpenSSL::X509::Request.new
            csr.version = 2
            csr.subject = OpenSSL::X509::Name.parse "C=#{@csr.c}/ST=#{@csr.st}/L=#{@csr.l}/O=#{@csr.o}/CN=#{@csr.cn}"
            csr.public_key = key.public_key
            csr.sign key, OpenSSL::Digest::SHA512.new
            open $root_dir + "/csrs/#{@csr.id}-#{@csr.cn}.pem", 'w' do |io|
              io.write csr.to_pem
            end
            redirect '/admin/csr'
          end
          
          delete '/admin/csr/:id' do
            @csr = RubyCA::Core::Models::CSR.get(params[:id])
            File.delete $root_dir + "/keys/#{@csr.id}-#{@csr.cn}.pem" if File.exist? $root_dir + "/keys/#{@csr.id}-#{@csr.cn}.pem"
            File.delete $root_dir + "/csrs/#{@csr.id}-#{@csr.cn}.pem" if File.exist? $root_dir + "/csrs/#{@csr.id}-#{@csr.cn}.pem"
            @csr.destroy
            redirect '/admin/csr'
          end
          
          get '/admin/csr/:id/sign' do
            @csr = RubyCA::Core::Models::CSR.get(params[:id])
            haml :sign
          end
        
          post '/admin/csr/:id/sign' do
            @csr = RubyCA::Core::Models::CSR.get(params[:id])
            crt_key = OpenSSL::PKey::RSA.new File.read($root_dir + "/keys/#{@csr.id}-#{@csr.cn}.pem"), params[:passphrase][:certificate]
            intermediate_key = OpenSSL::PKey::RSA.new ENC_INT_KEY, params[:passphrase][:intermediate]
            csr = OpenSSL::X509::Request.new File.read $root_dir + "/csrs/#{@csr.id}-#{@csr.cn}.pem"
            intermediate_crt = OpenSSL::X509::Certificate.new File.read $root_dir + "/core/web/public/#{CONFIG['ca']['intermediate']['name']}_Intermediate_CA.crt"
            crt = OpenSSL::X509::Certificate.new
            crt.serial = IO.binread($root_dir + '/core/ca/last_serial').to_i + 1
            open $root_dir + '/core/ca/last_serial', 'w' do |io|
              io.write crt.serial
            end
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
            crt.add_extension crt_ef.create_extension 'crlDistributionPoints', "URI:http://#{CONFIG['web']['host']}/ca.crl"
            crt.sign intermediate_key, OpenSSL::Digest::SHA512.new
            open $root_dir + "/certificates/#{@csr.id}-#{@csr.cn}.crt", 'w' do |io|
              io.write crt.to_pem
            end 
            redirect '/admin/csr'
          end

      end
    end
  end
end