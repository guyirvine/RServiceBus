
class MessageHandler_HelloWorld1

	attr_accessor :Bus

	def Handle( msg )
		puts 'Handling Hello World 1: ' + msg.name
		@Bus.Reply( 'Hey. ' + msg.name )
		@Bus.Send( HelloWorld2.new( 'From 1. ' + msg.name ) )
	end
end
