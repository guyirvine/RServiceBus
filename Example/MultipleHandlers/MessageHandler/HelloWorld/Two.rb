
class MessageHandler_HelloWorld_Two

	attr_accessor :Bus
	@Bus

	def Handle( msg )
		puts 'MessageHandler_HelloWorld_Two: HelloWorld'
		@Bus.Reply('Reply from MessageHandler_HelloWorld_Two')
	end
end
