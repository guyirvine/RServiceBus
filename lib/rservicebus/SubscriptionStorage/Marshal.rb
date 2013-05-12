module RServiceBus

#Implementation of Subscription Storage to Redis
class SubscriptionStorage_Marshal<SubscriptionStorage

	@path

    # Constructor
    #
    # @param [String] appName Name of the application, which is used as a Namespace
    # @param [String] uri a location for the resource to which we will attach, eg redis://127.0.0.1/foo
	def initialize( appName, uri )
		super(appName, uri)
	end

	def getAll
		RServiceBus.log "Load subscriptions"
        return Hash.new unless File.exists?( @uri.path )
        
        return YAML::load( File.open( @uri.path ) )
	end

	def add( eventName, queueName )
        if File.exists?( @uri.path ) then
            subscriptions = YAML::load( File.open( @uri.path ) )
        else
			subscriptions = Hash.new
        end
            
        subscriptions[eventName] = Array.new if subscriptions[eventName].nil?
		
		subscriptions[eventName] << queueName
		subscriptions[eventName] = subscriptions[eventName].uniq

        IO.write( @uri.path, YAML::dump(subscriptions ) )

		return subscriptions
	end

	def remove( eventName, queueName )
		raise "Method, remove, needs to be implemented for this subscription storage"
	end

end

end
