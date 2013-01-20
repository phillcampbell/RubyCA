if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

module RubyCA
  module Core
    module Models
    
      class CSR
          include DataMapper::Resource
          property :cn, String, unique: true, key: true
          property :o, String, required: true
          property :l, String, required: true
          property :st, String, required: true
          property :c, String, required: true
          property :csr, Text
          property :pkey, Text
      end
    
    end
  end
end