module RServiceBus

require "uri"

# Base class for subscription storage
#
class SubscriptionStorage
	@appName
    @uri

    # Constructor
    #
    # @param [String] appName Name of the application, which is used as a Namespace
    # @param [String] uri a location for the resource to which we will attach, eg redis://127.0.0.1/foo
	def initialize(appName, uri)
		@appName = appName
        @uri = uri
	end

    # Get a list of all subscription, as an Array
    #
    # @param [String] appName Name of the application, which is used as a Namespace
    # @param [String] uri a location for the resource to which we will attach, eg redis://127.0.0.1/foo
	def getAll
		raise "Method, getResource, needs to be implemented for resource"
	end

    # Add a new subscription
    #
    # @param [String] eventName Name of the event for which the subscriber has asked for notification
    # @param [String] queueName the queue to which the event should be sent
	def add( eventName, queueName )
		raise "Method, add, needs to be implemented for this subscription storage"
	end

    # Remove an existing subscription
    #
    # @param [String] eventName Name of the event for which the subscriber has asked for notification
    # @param [String] queueName the queue to which the event should be sent
	def remove( eventName, queueName )
		raise "Method, remove, needs to be implemented for this subscription storage"
	end
end

end
