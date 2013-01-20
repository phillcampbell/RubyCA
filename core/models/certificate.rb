module RubyCA
  module Core
    module Models
    
      class Certificate
          include DataMapper::Resource
          property :cn, String, unique: true, key: true
          property :crt, Text
          property :pkey, Text
      end
    
    end
  end
end