
class MessageHandler_HelloWorld

	attr_accessor :Bus, :Redis
	@Bus
	@Redis

	def Handle( msg )

		@Redis.set "id:#{msg.id}", msg.name
		
		@Bus.Publish( HelloWorldUpdated.new msg.id );
	end
end
