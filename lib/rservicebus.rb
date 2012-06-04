require "rubygems"
require "amqp"
require "yaml"
require "uuidtools"
require "log4r"
require "redis"
require "json"

require "rservicebus/helper_functions"
require "rservicebus/Agent"
require "rservicebus/ErrorMessage"
require "rservicebus/Message"
require "rservicebus/Subscription"
require "rservicebus/Config"
require "rservicebus/HandlerLoader"


include Log4r

module RServiceBus


class Host

	attr_reader :logger
	attr_writer :handlerList, :errorQueueName, :maxRetries, :localQueueName, :appName, :logger, :forwardReceivedMessagesTo, :messageEndpointMappings

	@appName

	@handlerList

	@errorQueueName
	@maxRetries

	@localQueueName
	
	@forwardReceivedMessagesTo
	@forwardReceivedMessagesToQueue
	
	@messageEndpointMappings

	@subscriptions
	
	# DEBUG < INFO < WARN < ERROR < FATAL
	@logger


	def initialize(configFilePath=nil)
		@forwardReceivedMessagesToQueue = nil
		RServiceBus::Config.new().loadConfig( self, configFilePath )
		@logger.info "MessageEndpointMappings: " + @messageEndpointMappings.to_s
	end


	def loadHandlers( baseDir="MessageHandler/*" )
		@logger.info "Load Message Handlers"
		@logger.debug "Checking, " + baseDir
		


		@handlerList = {};
		Dir[baseDir].each do |filePath|
			if !filePath.end_with?( "." ) then
				@logger.debug "Filepath, " + filePath
				
				if File.directory?( filePath ) then
					self.loadHandlers( filePath + "/*" )
				else
					handlerLoader = HandlerLoader.new( @logger, filePath, self )
					handlerLoader.loadHandler

					if !@handlerList.has_key?( handlerLoader.messageName ) then
						@handlerList[handlerLoader.messageName] = Array.new
					end
				
					@handlerList[handlerLoader.messageName] << handlerLoader.handler;
				end
			end
		end

		return self
	end

	def sendSubscriptions
		@logger.info "Send Subscriptions"
		@messageEndpointMappings.each do |eventName,queueName|
			@logger.debug "Checking, " + eventName + " for Event"
			if eventName.end_with?( "Event" ) then
				@logger.debug eventName + ", is an event. About to send subscription to, " + queueName
				self.Subscribe( eventName )
				@logger.info "Subscribed to, " + eventName + " at, " + queueName
			end
		end

		return self
	end

	def loadSubscriptions
		@logger.info "Load subscriptions"
		@subscriptions = Hash.new
		
		redis = Redis.new

		prefix = @appName + ".Subscriptions."
		subscriptions = redis.keys prefix + "*Event"

		subscriptions.each do |subscriptionName|
			@logger.debug "Loading subscription: " + subscriptionName
			eventName = subscriptionName.sub( prefix, "" )
			@subscriptions[eventName] = Array.new			

			@logger.debug "Loading for event: " + eventName
			subscription = redis.smembers subscriptionName
			subscription.each do |subscriber|
				@logger.debug "Loading subscriber, " + subscriber + " for event, " + eventName
				@subscriptions[eventName] << subscriber
			end
		end
		
		return self
	end

	def addSubscrption( eventName, queueName )
		@logger.info "Adding subscrption for, " + eventName + ", to, " + queueName
		redis = Redis.new
		key = @appName + ".Subscriptions." + eventName
		redis.sadd key, queueName

		if @subscriptions[eventName].nil? then
			@subscriptions[eventName] = Array.new
		end
		@subscriptions[eventName] << queueName
	end

	def run
		@logger.info "Starting the Host"

		AMQP.start(:host => "localhost") do |connection|
			@channel = AMQP::Channel.new(connection)
			@queue   = @channel.queue(@localQueueName)
			@errorQueue   = @channel.queue( @errorQueueName )
			if !@forwardReceivedMessagesTo.nil? then
				@logger.info "Forwarding all received messages to: " + @forwardReceivedMessagesTo.to_s
				@forwardReceivedMessagesToQueue = @channel.queue( @forwardReceivedMessagesTo )
			end

			Signal.trap("INT") do
				connection.close do
					EM.stop { exit }
				end
			end

			self.StartListeningToEndpoints
		end
	end


	def StartListeningToEndpoints
		@logger.info "Waiting for messages. To exit press CTRL+C"

		@queue.subscribe do |body|
			retries = @maxRetries
			begin
				@msg = YAML::load(body)
				if @msg.msg.class.name == "RServiceBus::Subscription" then
					self.addSubscrption( @msg.msg.eventName, @msg.returnAddress )
				else
					self.HandleMessage()
					if !@forwardReceivedMessagesTo.nil? then
						@channel.default_exchange.publish(body, :routing_key => @forwardReceivedMessagesTo)
					end
				end
	    	rescue Exception => e
		    	retry if (retries -= 1) > 0

				errorString = e.message + ". " + e.backtrace[0]
				@logger.error errorString

				@msg.addErrorMsg( @queue.name, errorString )
				serialized_object = YAML::dump(@msg)
				@channel.default_exchange.publish(serialized_object, :routing_key => @errorQueueName)
    		end
		end
	end

	def HandleMessage()
		msgName = @msg.msg.class.name
		handlerList = @handlerList[msgName]

		if handlerList == nil then
			@logger.warn "No handler found for: " + msgName
			raise "No Handler Found"
	    else
			@logger.debug "Handler found for: " + msgName
			begin
				handlerList.each do |handler|
		   			handler.Handle( @msg.msg )
		   		end
	   		rescue Exception => e
				@logger.error "An error occured in Handler: " + handler.class.name
				raise e
	   		end
    	end
	end

	def __Send( msg, queueName, channel )
		@logger.debug "Bus.__Send"

		rMsg = RServiceBus::Message.new( msg, @localQueueName )
		serialized_object = YAML::dump(rMsg)

		queue = channel.queue(queueName)
		@logger.debug "Sending: " + msg.class.name + " to: " + queueName
		channel.default_exchange.publish(serialized_object, :routing_key => queueName)
	end

	def _Send( msg, queueName )
		@logger.debug "Bus._Send"

		if @channel.nil? then
			AMQP.start(:host => "localhost") do |connection|
				channel = AMQP::Channel.new(connection)
				self.__Send( msg, queueName, channel )

				EM.add_timer(0.1) do
					connection.close do
						EM.stop { exit }
					end
				end

			end
		else
			self.__Send( msg, queueName, @channel )
		end
	end

	def Reply( msg )
		@logger.debug "Reply with: " + msg.class.name + " To: " + @msg.returnAddress

		rMsg = RServiceBus::Message.new( msg, @localQueueName )
		serialized_object = YAML::dump(rMsg)

		self._Send( msg, @msg.returnAddress )
	end


	def Send( msg )
		@logger.debug "Bus.Send"


		msgName = msg.class.name
		if !@messageEndpointMappings.has_key?( msgName ) then
			@logger.warn "No end point mapping found for: " + msgName
			@logger.warn "**** Check in RServiceBus.yml that the section MessageEndpointMappings contains an entry named : " + msgName
			raise "No end point mapping found for: " + msgName
		end

		queueName = @messageEndpointMappings[msgName]
		
		self._Send( msg, queueName )
	end

	def Publish( msg )
		@logger.debug "Bus.Publish"


		subscription = @subscriptions[msg.class.name]
		if subscription.nil? then
			@logger.info "No subscribers for event, " + msg.class.name
			return
		end

		subscription.each do |subscriber|
			self._Send( msg, subscriber )
		end

		
	end

	def Subscribe( eventName )
		@logger.debug "Bus.Subscribe: " + eventName


		queueName = @messageEndpointMappings[eventName]
		subscription = Subscription.new( eventName )


		self._Send( subscription, queueName )
	end

end


end
