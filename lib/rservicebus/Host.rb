module RServiceBus

class Host

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
	
	@beanstalk

	@verbose
	@appResources

	def log(string, ver=false)
		type = ver ? "VERB" : "INFO"
		if @verbose || !ver then
			timestamp = Time.new.strftime( "%Y-%m-%d %H:%M:%S" )
			puts "[#{type}] #{timestamp} :: #{string}"
		end
	end

	def getValue( name, default=nil )
		value = ENV["#{name}"].nil? ? default : ENV["#{name}"];
		self.log "Env value: #{name}: #{value}", true
		return value
	end

	def loadMessageEndpointMappings()
		mapping = self.getValue( "MESSAGE_ENDPOINT_MAPPINGS" )

		messageEndpointMappings=Hash.new
		if !mapping.nil? then
			mapping.split( ";" ).each do |line|
				match = line.match( /(.+):(.+)/ )
				messageEndpointMappings[match[0]] = match[1]
			end
		end

		@messageEndpointMappings=messageEndpointMappings

		return self
	end

	def loadHandlerPathList()
		path = self.getValue( "MSGHANDLERPATH", "MessageHandler" )
		handlerPathList = Array.new
		path.split( ";" ).each do |path|
			path = path.strip.chomp( "/" )
			handlerPathList << path
		end

		@handlerPathList = handlerPathList

		return self
	end


	def loadHostSection()
		@appName = self.getValue( "APPNAME", "RServiceBus" )
		@localQueueName = @appName
		@errorQueueName = self.getValue( "ERROR_QUEUE_NAME", "error" )
		@maxRetries = self.getValue( "MAX_RETRIES", "5" ).to_i
		@forwardReceivedMessagesTo = self.getValue( "FORWARD_RECEIVED_MESSAGES_TO" )

		return self
	end

	def loadContracts()
		if self.getValue( "CONTRACTS" ).nil? then
			return self
		end

		self.getValue( "CONTRACTS" ).split( ";" ).each do |path|
			self.log "Loading contracts from, #{path}"
			require path
		end
		return self
	end

	def configureLogging()
		@verbose = !self.getValue( "VERBOSE", nil ).nil?

		return self
	end

	def configureBeanstalk
		beanstalkHost = self.getValue( "BEANSTALK", "localhost:11300" )
		begin
			@beanstalk = Beanstalk::Pool.new([beanstalkHost])
		rescue Exception => e
			if e.message == "Beanstalk::NotConnected" then
				puts "Error connecting to Beanstalk"
				puts "***Most likely, beanstalk is not running. Start beanstalk, and try running this again."
				puts "***If you still get this error, check beanstalk is running at, " + beanstalkHost
				abort()
			else
				raise e
			end
		end

		return self
	end

	def configureAppResource
		@appResources = ConfigureAppResource.new.getResources( ENV )
		return self;
	end

	def initialize()

		self.configureLogging()
			.loadHostSection()
			.configureBeanstalk()
			.configureAppResource()
			.loadContracts()
			.loadMessageEndpointMappings()
			.loadHandlerPathList()
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

		@handlerPathList.each do |path|
			self.loadHandlersFromPath(path)
		end

		return self
	end

	def sendSubscriptions
		log "Send Subscriptions"
		@messageEndpointMappings.each do |eventName,queueName|
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

		prefix = @appName + ".Subscriptions."
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
		key = @appName + ".Subscriptions." + eventName
		redis.sadd key, queueName

		if @subscriptions[eventName].nil? then
			@subscriptions[eventName] = Array.new
		end
		@subscriptions[eventName] << queueName
	end

	def run
		log "Starting the Host"

		log "Watching, " + @localQueueName
		@beanstalk.watch( @localQueueName )
		if !@forwardReceivedMessagesTo.nil? then
			log "Forwarding all received messages to: " + @forwardReceivedMessagesTo.to_s
		end

		self.StartListeningToEndpoints
	end


	def StartListeningToEndpoints
		log "Waiting for messages. To exit press CTRL+C"

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
				log errorString

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

		rMsg = RServiceBus::Message.new( msg, @localQueueName )
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
		if !@messageEndpointMappings.has_key?( msgName ) then
			log "No end point mapping found for: " + msgName
			log "**** Check in RServiceBus.yml that the section MessageEndpointMappings contains an entry named : " + msgName
			raise "No end point mapping found for: " + msgName
		end

		queueName = @messageEndpointMappings[msgName]
		
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


		queueName = @messageEndpointMappings[eventName]
		subscription = Subscription.new( eventName )


		self._SendNeedsWrapping( subscription, queueName )
	end

end

end
