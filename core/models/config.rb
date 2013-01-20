if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

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