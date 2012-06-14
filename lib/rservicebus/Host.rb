module RServiceBus

class Host


	@handlerList

	@forwardReceivedMessagesToQueue

	@subscriptions
	
	@beanstalk

	@appResources
	
	
	@config

	def log(string, ver=false)
		type = ver ? "VERB" : "INFO"
		if @config.verbose || !ver then
			timestamp = Time.new.strftime( "%Y-%m-%d %H:%M:%S" )
			puts "[#{type}] #{timestamp} :: #{string}"
		end
	end

	def configureAppResource
		@appResources = ConfigureAppResource.new.getResources( ENV )
		return self;
	end

	def connectToBeanstalk
		begin
			@beanstalk = Beanstalk::Pool.new([@config.beanstalkHost])
		rescue Exception => e
			puts "Error connecting to Beanstalk"
			puts "Host string, #{@config.beanstalkHost}"
			if e.message == "Beanstalk::NotConnected" then
				puts "***Most likely, beanstalk is not running. Start beanstalk, and try running this again."
				puts "***If you still get this error, check beanstalk is running at, " + beanstalkHost
			else
				puts e.message
				puts e.backtrace
			end
			abort()
		end

		return self
	end

	def initialize()

		@config = ConfigFromEnv.new
			.configureLogging()
			.loadHostSection()
			.configureBeanstalk()
			.loadContracts()
			.loadMessageEndpointMappings()
			.loadHandlerPathList();

		self.configureAppResource()
			.connectToBeanstalk()
			.loadHandlers()
			.loadSubscriptions()
			.sendSubscriptions()

		return self
	end

	def loadHandlersFromPath(baseDir, subDir="")
		log "Load Message Handlers from baseDir, " + baseDir + ", subDir, " + subDir
		log "Checking, " + baseDir, true
		handlerLoader = HandlerLoader.new( self, @appResources )

		@handlerList = {};
		Dir[baseDir + "/" + subDir + "*"].each do |filePath|
			if !filePath.end_with?( "." ) then
				log "Filepath, " + filePath, true

				if File.directory?( filePath ) then
					self.loadHandlersFromPath( filePath.sub( baseDir ) )
				else
					messageName, handler = handlerLoader.loadHandler( baseDir, filePath )

					if !@handlerList.has_key?( messageName ) then
						@handlerList[messageName] = Array.new
					end

					@handlerList[messageName] << handler;
				end
			end
		end

		return self
	end

	def loadHandlers()
		log "Load Message Handlers"

		@config.handlerPathList.each do |path|
			self.loadHandlersFromPath(path)
		end

		return self
	end

	def sendSubscriptions
		log "Send Subscriptions"
		@config.messageEndpointMappings.each do |eventName,queueName|
			log "Checking, " + eventName + " for Event", true
			if eventName.end_with?( "Event" ) then
				log eventName + ", is an event. About to send subscription to, " + queueName, true
				self.Subscribe( eventName )
				log "Subscribed to, " + eventName + " at, " + queueName
			end
		end

		return self
	end

	def loadSubscriptions
		log "Load subscriptions"
		@subscriptions = Hash.new
		
		redis = Redis.new

		prefix = @config.appName + ".Subscriptions."
		subscriptions = redis.keys prefix + "*Event"

		subscriptions.each do |subscriptionName|
			log "Loading subscription: " + subscriptionName, true
			eventName = subscriptionName.sub( prefix, "" )
			@subscriptions[eventName] = Array.new			

			log "Loading for event: " + eventName, true
			subscription = redis.smembers subscriptionName
			subscription.each do |subscriber|
				log "Loading subscriber, " + subscriber + " for event, " + eventName, true
				@subscriptions[eventName] << subscriber
			end
		end
		
		return self
	end

	def addSubscrption( eventName, queueName )
		log "Adding subscrption for, " + eventName + ", to, " + queueName
		redis = Redis.new
		key = @config.appName + ".Subscriptions." + eventName
		redis.sadd key, queueName

		if @subscriptions[eventName].nil? then
			@subscriptions[eventName] = Array.new
		end
		@subscriptions[eventName] << queueName
	end

	def run
		log "Starting the Host"

		log "Watching, " + @config.localQueueName
		@beanstalk.watch( @config.localQueueName )
		if !@config.forwardReceivedMessagesTo.nil? then
			log "Forwarding all received messages to: " + @config.forwardReceivedMessagesTo.to_s
		end

		self.StartListeningToEndpoints
	end


	def StartListeningToEndpoints
		log "Waiting for messages. To exit press CTRL+C"

		loop do
			job = @beanstalk.reserve
			body = job.body
			retries = @config.maxRetries
			begin
				@msg = YAML::load(body)
				if @msg.msg.class.name == "RServiceBus::Subscription" then
					self.addSubscrption( @msg.msg.eventName, @msg.returnAddress )
				else
					self.HandleMessage()
					if !@config.forwardReceivedMessagesTo.nil? then
						self._SendAlreadyWrappedAndSerialised(body,@config.forwardReceivedMessagesTo)
					end
				end
				job.delete
	    	rescue Exception => e
		    	retry if (retries -= 1) > 0		    	

				errorString = e.message + ". " + e.backtrace[0]
				log errorString

				@msg.addErrorMsg( @config.localQueueName, errorString )
				serialized_object = YAML::dump(@msg)
				self._SendAlreadyWrappedAndSerialised(serialized_object, @config.errorQueueName)
    		end
		end
	end

	def HandleMessage()
		msgName = @msg.msg.class.name
		handlerList = @handlerList[msgName]

		if handlerList == nil then
			log "No handler found for: " + msgName
			raise "No Handler Found"
	    else
			log "Handler found for: " + msgName, true
				handlerList.each do |handler|
					begin
			   			handler.Handle( @msg.msg )
	   				rescue Exception => e
						log "An error occured in Handler: " + handler.class.name
						raise e
			   		end
		   		end
    	end
	end

	def _SendAlreadyWrappedAndSerialised( serialized_object, queueName )
		log "Bus._SendAlreadyWrappedAndSerialised", true

		@beanstalk.use( queueName )
		@beanstalk.put( serialized_object )
	end

	def _SendNeedsWrapping( msg, queueName )
		log "Bus._SendNeedsWrapping", true

		rMsg = RServiceBus::Message.new( msg, @config.localQueueName )
		serialized_object = YAML::dump(rMsg)
		log "Sending: " + msg.class.name + " to: " + queueName, true
		self._SendAlreadyWrappedAndSerialised( serialized_object, queueName )
	end

	def Reply( msg )
		log "Reply with: " + msg.class.name + " To: " + @msg.returnAddress, true

		self._SendNeedsWrapping( msg, @msg.returnAddress )
	end


	def Send( msg )
		log "Bus.Send", true


		msgName = msg.class.name
		if !@config.messageEndpointMappings.has_key?( msgName ) then
			log "No end point mapping found for: " + msgName
			log "**** Check in RServiceBus.yml that the section MessageEndpointMappings contains an entry named : " + msgName
			raise "No end point mapping found for: " + msgName
		end

		queueName = @config.messageEndpointMappings[msgName]
		
		self._SendNeedsWrapping( msg, queueName )
	end

	def Publish( msg )
		log "Bus.Publish", true


		subscription = @subscriptions[msg.class.name]
		if subscription.nil? then
			log "No subscribers for event, " + msg.class.name
			return
		end

		subscription.each do |subscriber|
			self._SendNeedsWrapping( msg, subscriber )
		end

		
	end

	def Subscribe( eventName )
		log "Bus.Subscribe: " + eventName, true


		queueName = @config.messageEndpointMappings[eventName]
		subscription = Subscription.new( eventName )


		self._SendNeedsWrapping( subscription, queueName )
	end

end

end
