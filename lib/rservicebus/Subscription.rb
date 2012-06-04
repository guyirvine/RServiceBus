module RServiceBus


class Subscription
	attr_reader :eventName

	def initialize( eventName )
		@eventName=eventName
	end
	
end

end
