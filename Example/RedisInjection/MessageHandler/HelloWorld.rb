require "./Contract.rb"

class MessageHandler_HelloWorld

	attr_accessor :Bus, :Redis

	@Bus
	@Redis

	def Handle( msg )
#raise "Manually generated error for testng"
		puts "Handling Hello World: " + msg.name
		@Bus.Reply( "Hey" )
	end
end
