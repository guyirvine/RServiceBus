
class MessageHandler_HelloWorld2

	attr_accessor :Bus

	def Handle( msg )
		puts 'Handling Hello World2: ' + msg.name
	end
end
