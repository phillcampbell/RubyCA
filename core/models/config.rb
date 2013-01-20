module RubyCA
  module Core
    module Models
    
      class Config
          include DataMapper::Resource
          property :name, String, unique: true, key: true
          property :value, String, required: true
      end
    
    end
  end
end