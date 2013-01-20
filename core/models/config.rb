module RubyCA
  module Core
    module Models
    
      class Config
          include DataMapper::Resource
          property :name, Text, unique: true, key: true
          property :value, Text, required: true
      end
    
    end
  end
end