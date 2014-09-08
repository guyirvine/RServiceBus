require './Contract.rb'

class MessageHandler_HelloWorldEvent

	attr_writer :Bus
	attr_reader :Bus
	@Bus

	def Handle( msg )
		puts 'Handling Hello World: ' + msg.name
	end
end
