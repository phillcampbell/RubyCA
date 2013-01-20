if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

module RubyCA
  module Core
    class Privileges
      
      def self.drop
        # Drop privileges
        puts ''
        puts 'Dropping privileges...'
        Process::Sys.setuid(Etc.getpwnam(CONFIG['privileges']['user']).uid)
        # Check RubyCA has drops its privileges successfully
        begin
          Process::Sys.setuid(0)
        rescue Errno::EPERM
          puts "Successfully dropped privileges. RubyCA is now '#{Etc.getpwuid(Process.euid).name}'"
        else
          puts 'Error: Failed to drop privileges, RubyCA will now exit.'
          abort
        end
      end
      
    end
  end
end

# Overrride to drop privileges after opening port in WEBrick
# module WEBrick
#   GenericServer.class_eval do 
#     
#     def listen(address, port)
#       @listeners += Utils::create_listeners(address, port, @logger)
#       RubyCA::Core::Privileges.drop
#     end
#     
#   end
# end

# Overrride to drop privileges after opening port in Thin
module EventMachine
  self.class_eval do 
    def self.start_server server, port=nil, handler=nil, *args, &block
      begin
        port = Integer(port)
      rescue ArgumentError, TypeError
        # there was no port, so server must be a unix domain socket
        # the port argument is actually the handler, and the handler is one of the args
        args.unshift handler if handler
        handler = port
        port = nil
      end if port

      klass = klass_from_handler(Connection, handler, *args)

      s = if port
            start_tcp_server server, port
          else
            start_unix_server server
          end
      RubyCA::Core::Privileges.drop
      @acceptors[s] = [klass,args,block]
      s
    end
  end
end
