module RServiceBus

require "uri"

# Base class for subscription storage
#
class SubscriptionStorage
	@appName

# Specified using URI.
#
# @param [String] uri a location for the resource to which we will attach, eg redis://127.0.0.1/foo
	def initialize(appName, uri)
		@appName = appName
	end

	def getAll
		raise "Method, getResource, needs to be implemented for resource"
	end

	def add( eventName, queueName )
		raise "Method, add, needs to be implemented for this subscription storage"
	end

	def remove( eventName, queueName )
		raise "Method, remove, needs to be implemented for this subscription storage"
	end
end

end
