require './Contract.rb'

class MessageHandler_HelloWorld

	attr_writer :Bus
	attr_reader :Bus
	@Bus

	def Handle( msg )
		@Bus.Publish( HelloWorldEvent.new('Hello World') )
	end
end
