module RubyCA
  module Core
    module Web
      
      class Manager < Sinatra::Base
        set :environment, :production
        set :bind, CONFIG['web']['manager']['host']
        set :port, CONFIG['web']['manager']['port']
        
        before '*' do
          unless CONFIG['web']['manager']['allowed_ips'].include? request.ip
            halt 401, '401 Unauthorised'
          end
        end
        
        get '/' do
          "Hello World!"
        end
        
        if CONFIG['web']['manager']['enabled'] then run! end
        
      end
      
    end
  end
end