if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

VERSION=IO.binread($root_dir + '/version')

# Print welcome message
puts ''
puts "RubyCA Version #{VERSION}"
puts '------------------'
puts Time.now.strftime("%H:%M:%S %d-%m-%Y %Z")
# These requires allow the Gemfile to work
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

# Requires
require 'singleton'
require "sinatra/reloader"

# Test config file exists
CFG_FILE = $root_dir + '/config/rubyca.yaml'
unless File.exists?(CFG_FILE) or File.file?(CFG_FILE)
  puts ''
  puts 'Error: RubyCA requires config/rubyca.yaml'
  puts "Please run create it"
  puts "You can learn more about this in readme.md"
  puts '------------------'
  abort
end
# Load config into global CONFIG
CONFIG = YAML.load(File.read(CFG_FILE))
