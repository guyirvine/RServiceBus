require "./Contract.rb"

class MessageHandler_HelloWorld

	attr_accessor :Bus, :Redis

	def Handle( msg )
#raise "Manually generated error for testng"
		puts "Handling Hello World: " + msg.name
		@Bus.Reply( "Hey." + @Redis.get( msg.name ) )
	end
end
