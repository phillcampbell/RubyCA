module RubyCA
  module Core
    module Models
    
      class CSR
          include DataMapper::Resource
          property :id, Serial
          property :cn, String, required: true
          property :o, String, required: true
          property :l, String, required: true
          property :st, String, required: true
          property :c, String, required: true
      end
    
    end
  end
end