if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

module RubyCA
  module Core
    module Models
    
      class Certificate
          include DataMapper::Resource
          property :id, Serial
          property :cn, String, key: true, :length => 64, unique: true, :required => true
          property :crt, Text
          property :pkey, Text
          
          def self.get_by_cn(param_cn)
            self.all(:cn => param_cn).first unless self.count == 0
          end
      end
    
    end
  end
end