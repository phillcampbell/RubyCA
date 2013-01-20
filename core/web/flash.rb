if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

module Sinatra
  module Flash
    Style.module_eval do

      def styled_flash(key=:flash)
        return "" if flash(key).empty?
        id = (key == :flash ? "flash" : "flash_#{key}")
        messages = flash(key).collect {|message| "  <div class='alert alert-#{message[0]}'><button type='button' class='close' data-dismiss='alert'>&times;</button><strong>#{message[0].capitalize}: </strong>#{message[1]}</div>\n"}
        messages.join
      end
      
    end
  end
end