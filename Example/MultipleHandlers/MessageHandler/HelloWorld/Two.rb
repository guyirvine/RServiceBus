require "./Contract.rb"

class MessageHandler_HelloWorld_Two

	attr_writer :Bus
	attr_reader :Bus
	@Bus

	def Handle( msg )
#raise "Manually generated error for testng"
		puts "Two. Handling Hello World: " + msg.name
		@Bus.Reply( "Hey" )
	end
end
