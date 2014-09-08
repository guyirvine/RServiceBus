module RServiceBus

require 'redis'

#Implementation of Subscription Storage to Redis
class SubscriptionStorage_Redis<SubscriptionStorage

	@redis

    # Constructor
    #
    # @param [String] appName Name of the application, which is used as a Namespace
    # @param [String] uri a location for the resource to which we will attach, eg redis://127.0.0.1/foo
	def initialize( appName, uri )
		super(appName, uri)
        port = uri.port.nil? ? 6379 : uri.port
		@redis = Redis.new( :host=>uri.host, :port=>port )
	end

	def getAll
		RServiceBus.log 'Load subscriptions'
		begin
			content = @redis.get( @appName + '.Subscriptions')
			if content.nil? then
				subscriptions = Hash.new
			else
				subscriptions = YAML::load(content)
			end
			return subscriptions
		rescue Exception => e
			puts 'Error connecting to redis'
			if e.message == 'Redis::CannotConnectError' ||
					e.message == 'Redis::ECONNREFUSED' then
				puts '***Most likely, redis is not running. Start redis, and try running this again.'
			else
				puts e.message
				puts e.backtrace
			end
			abort()
		end
	end

	def add( eventName, queueName )
		content = @redis.get( @appName + '.Subscriptions')
		if content.nil? then
			subscriptions = Hash.new
		else
			subscriptions = YAML::load(content)
		end

		if subscriptions[eventName].nil? then
			subscriptions[eventName] = Array.new
		end
		
		subscriptions[eventName] << queueName
		subscriptions[eventName] = subscriptions[eventName].uniq

		@redis.set( @appName + '.Subscriptions', YAML::dump(subscriptions ) )

		return subscriptions
	end

	def remove( eventName, queueName )
		raise 'Method, remove, needs to be implemented for this subscription storage'
	end

end

end
