module RServiceBus


class Message_Subscription
	attr_reader :eventName

	def initialize( eventName )
		@eventName=eventName
	end
	
end

end
