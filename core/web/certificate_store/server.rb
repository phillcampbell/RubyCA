module RubyCA
  module Core
    module Web
      module CertificateStore
        class Server < Sinatra::Base
          get '/' do
            'Implement index'
          end
        end
      end
    end
  end
end