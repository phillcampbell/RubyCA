if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

module RubyCA
  module Core
    module Models
    
      class CSR
          include DataMapper::Resource
          property :cn, String, :length => 64, unique: true, key: true
          property :o, String, :length => 64, required: true
          property :l, String, :length => 64, required: true
          property :st, String, :length => 64, required: true
          property :c, String, :length => 64, required: true
          property :csr, Text
          property :pkey, Text
      end
    
    end
  end
end