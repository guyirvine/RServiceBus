module RServiceBus

class Host

	attr_reader :logger
	attr_writer :handlerPathList, :handlerList, :errorQueueName, :maxRetries, :localQueueName, :appName, :logger, :forwardReceivedMessagesTo, :messageEndpointMappings

	@appName


	@handlerPathList
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

	@beanstalk

	def loadConfig(configFilePath=nil)
		@forwardReceivedMessagesToQueue = nil
		RServiceBus::ConfigFromFile.new(configFilePath).processConfig( self )
		@logger.info "MessageEndpointMappings: " + @messageEndpointMappings.to_s
		
		return self
	end


	def loadHandlersFromPath(baseDir)
		@logger.info "Load Message Handlers From Path"
		@logger.debug "Checking, " + baseDir

		@handlerList = {};
		Dir[baseDir + "/*"].each do |filePath|
			if !filePath.end_with?( "." ) then
				@logger.debug "Filepath, " + filePath

				if File.directory?( filePath ) then
					self.loadHandlersFromPath( filePath )
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

	def loadHandlers()
		@logger.info "Load Message Handlers"

		@handlerPathList.each do |path|
			self.loadHandlersFromPath(path)
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


		@beanstalk = Beanstalk::Pool.new(['localhost:11300'])
		@beanstalk.watch( @localQueueName )
		if !@forwardReceivedMessagesTo.nil? then
			@logger.info "Forwarding all received messages to: " + @forwardReceivedMessagesTo.to_s
		end

		self.StartListeningToEndpoints
	end


	def StartListeningToEndpoints
		@logger.info "Waiting for messages. To exit press CTRL+C"

		loop do
			job = @beanstalk.reserve
			body = job.body
			retries = @maxRetries
			begin
				@msg = YAML::load(body)
				if @msg.msg.class.name == "RServiceBus::Subscription" then
					self.addSubscrption( @msg.msg.eventName, @msg.returnAddress )
				else
					self.HandleMessage()
					if !@forwardReceivedMessagesTo.nil? then
						self._SendAlreadyWrappedAndSerialised(body,@forwardReceivedMessagesTo)
					end
				end
				job.delete
	    	rescue Exception => e
		    	retry if (retries -= 1) > 0		    	

				errorString = e.message + ". " + e.backtrace[0]
				@logger.error errorString

				@msg.addErrorMsg( @localQueueName, errorString )
				serialized_object = YAML::dump(@msg)
				self._SendAlreadyWrappedAndSerialised(serialized_object, @errorQueueName)
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
				handlerList.each do |handler|
					begin
			   			handler.Handle( @msg.msg )
	   				rescue Exception => e
						@logger.error "An error occured in Handler: " + handler.class.name
						raise e
			   		end
		   		end
    	end
	end

	def _SendAlreadyWrappedAndSerialised( serialized_object, queueName )
		@logger.debug "Bus._SendAlreadyWrappedAndSerialised"

		@beanstalk.use( queueName )
		@beanstalk.put( serialized_object )
	end

	def _SendNeedsWrapping( msg, queueName )
		@logger.debug "Bus._SendNeedsWrapping"

		rMsg = RServiceBus::Message.new( msg, @localQueueName )
		serialized_object = YAML::dump(rMsg)
		@logger.debug "Sending: " + msg.class.name + " to: " + queueName
		self._SendAlreadyWrappedAndSerialised( msg, queueName )
	end

	def Reply( msg )
		@logger.debug "Reply with: " + msg.class.name + " To: " + @msg.returnAddress

		self._SendNeedsWrapping( msg, @msg.returnAddress )
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
