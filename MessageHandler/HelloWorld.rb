class HelloWorld
	attr_reader :name
	def initialize( name )
		@name = name
	end
end


class MessageHandler_HelloWorld

	attr_writer :Bus
	attr_reader :Bus
	@Bus

	def Handle( msg )
		puts "Handling Hello World: " + msg.name
		@Bus.Reply( "Hey" )
	end
end
