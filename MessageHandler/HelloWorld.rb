class HelloWorld
	attr_reader :name
	def initialize( name )
		@name = name
	end
end


class MessageHandler_HelloWorld
	def Handle( msg )
		puts "Handling Hello World: " + msg.name
	end
end
