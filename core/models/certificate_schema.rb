if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

module RubyCA
  module Core
    module Models
    
      class CertificateSchema
          include DataMapper::Resource
          property :id, Serial
          property :o, String, :length => 64
          property :l, String, :length => 64
          property :st, String, :length => 64
          property :c, String, :length => 64
      end
    end
  end
end