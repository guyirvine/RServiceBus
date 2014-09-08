require 'HelperClass'
require 'BaseHelperClass'

class MessageHandler_HelloWorld

	attr_accessor :Bus

	def Handle( msg )
#raise "Manually generated error for testng"
		puts 'Handling Hello World: ' + msg.name
		@Bus.Reply( HelperClass.new.GetMsg )
	end
end
