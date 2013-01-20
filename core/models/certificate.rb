module RubyCA
  module Core
    module Models
    
      class Certificate
          include DataMapper::Resource
          property :id, Serial
          property :cn, String, required: true
          property :crt, Text
          property :pkey, Text
      end
    
    end
  end
end