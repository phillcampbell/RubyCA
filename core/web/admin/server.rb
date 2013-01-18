module RubyCA
  module Core
    module Web
      module Admin
        class Server < Sinatra::Base
          set :haml, layout: :layout
        
          before '*' do
            unless CONFIG['web']['admin']['allowed_ips'].include? request.ip
              halt 401, '401 Unauthorised'
            end
          end
        
          get '/csr' do
            haml :csr
          end
        
          post '/sign' do
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
end