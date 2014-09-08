
class MessageHandler_HelloWorld1

	attr_accessor :Bus

	def Handle( msg )
		puts 'Handling Hello World1: ' + msg.name
		@Bus.Send( HelloWorld2.new( 'Hey. ' + msg.name ) )
	end
end
