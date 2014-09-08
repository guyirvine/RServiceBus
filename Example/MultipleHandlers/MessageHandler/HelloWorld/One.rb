
class MessageHandler_HelloWorld_One

	attr_accessor :Bus

	def Handle( msg )
		puts 'MessageHandler_HelloWorld_One: HelloWorld'
		@Bus.Reply('Reply from MessageHandler_HelloWorld_One')
	end
end
