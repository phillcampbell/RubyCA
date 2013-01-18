module RubyCA
  module Core
    module Web
      
      class Manager < Sinatra::Base
        
        before '*' do
          unless CONFIG['web']['manager']['allowed_ips'].include? request.ip
            halt 401, '401 Unauthorised'
          end
        end
        
        get '/' do
          "Hello World!"
        end
        
      end
      
    end
  end
end