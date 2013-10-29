$LOAD_PATH.unshift(File.dirname(__FILE__))
$root_dir = File.expand_path('..', __FILE__)

require 'core/load'
require 'core/bootstrap'

run RubyCA::Core::Web::Server
