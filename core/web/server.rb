module RubyCA
  module Core
    module Web

        class Server < Sinatra::Base
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
                cn: params['csr']['cn'],
                o: params['csr']['o'],
                l: params['csr']['l'],
                st: params['csr']['st'],
                c: params['csr']['c'] )
            redirect '/admin/csr'
          end
        
          post '/admin/sign' do
            params[:csr]
            # cipher = OpenSSL::Cipher::Cipher.new 'AES-256-CBC'
            # key = OpenSSL::PKey::RSA.new 2048
            # open $root_dir + "/keys/#{params[:csr]['CN']}.pem", 'w', 0440 do |io|
            #   io.write key.export(cipher, params[:csr]['passphrase'])
            # end
          end

      end
    end
  end
end