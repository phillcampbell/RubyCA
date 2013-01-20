if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

require 'core/privileges'

DataMapper::Logger.new($stdout, :debug)
DataMapper::setup(:default, "sqlite3://#{$root_dir}/RubyCA.db")
require 'core/models/csr'
DataMapper.finalize
RubyCA::Core::Models::CSR.auto_upgrade!

require 'core/ca/setup'

require 'core/web/server'
# require 'core/web/certificate_store/server'