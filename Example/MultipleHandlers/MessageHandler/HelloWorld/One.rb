require "./Contract.rb"

class MessageHandler_HelloWorld_One

	attr_writer :Bus
	attr_reader :Bus
	@Bus

	def Handle( msg )
#raise "Manually generated error for testng"
		puts "One. Handling Hello World: " + msg.name
		@Bus.Reply( "Hey" )
	end
end
