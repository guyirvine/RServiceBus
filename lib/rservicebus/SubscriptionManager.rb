module RServiceBus

class SubscriptionManager

	@subscriptionStorage
	@subscriptions

	def initialize( subscriptionStorage )
		@subscriptionStorage = subscriptionStorage
		@subscriptions = @subscriptionStorage.getAll
	end

	#Get subscriptions for given eventName
	def get( eventName )
		subscriptions = @subscriptions[eventName]
		if subscriptions.nil? then
			RServiceBus.log "No subscribers for event, #{eventName}"
			RServiceBus.log "If there should be, ensure you have the appropriate evironment variable set, eg MESSAGE_ENDPOINT_MAPPINGS=#{eventName}:<Queue Name>"
            
			return Array.new
		end

		return subscriptions
	end

	def add( eventName, queueName )
		RServiceBus.log "Adding subscrption for, " + eventName + ", to, " + queueName
		@subscriptions = @subscriptionStorage.add( eventName, queueName )
	end

	def remove( eventName, queueName )
		raise "Method, remove, needs to be implemented for this subscription storage"
	end
end

end
