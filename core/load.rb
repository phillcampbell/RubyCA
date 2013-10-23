if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

# Print welcome message
puts ''
puts "RubyCA Version #{IO.binread($root_dir + '/version')}"
puts '------------------'

# These requires allow the Gemfile to work
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

# Requires
require 'singleton'

# Test config.yml exists
cfg_file = $root_dir + '/config.yaml'
unless File.exists?(cfg_file) or File.file?(cfg_file)
  puts ''
  puts 'Error: RubyCA requires config.yaml'
  puts "Please run create it"
  puts "You can learn more about this in readme.md"
  puts '------------------'
  abort
end
# Load config.yaml into global CONFIG
CONFIG = YAML.load(File.read(cfg_file)) 