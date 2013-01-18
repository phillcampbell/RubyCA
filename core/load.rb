if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

# Print welcome message
puts ''
puts "RubyCA Version #{IO.binread($root_dir + '/version')}"
puts '------------------'
puts ''

# These requires allow the Gemfile to work
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

# Requires
require 'singleton'

# Load config.yaml into global CONFIG
CONFIG = YAML.load(File.read($root_dir + '/config.yaml'))