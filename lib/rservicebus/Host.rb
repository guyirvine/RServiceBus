module RServiceBus

#Host process for rservicebus
class Host

	@handlerList

	@forwardReceivedMessagesToQueue

	@subscriptions
	
	@beanstalk

	@appResources	
	
	@config
	
	@subscriptionManager
	
	@stats

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

#Subscriptions are specified by adding events to the
#msg endpoint mapping
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

	def loadHandlers()
		log "Load Message Handlers"
		handlerLoader = HandlerLoader.new( self, @appResources )

		@config.handlerPathList.each do |path|
			handlerLoader.loadHandlersFromPath(path)
		end

		@handlerList = handlerLoader.handlerList

		return self
	end

	def configureSubscriptions
		subscriptionStorage = SubscriptionStorage_Redis.new( @config.appName, "uri" )
		@subscriptionManager = SubscriptionManager.new( subscriptionStorage )
		
		return self
	end

	def configureStatistics
		@stats = Stats.new
		
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

		self.configureStatistics()
			.configureAppResource()
			.connectToBeanstalk()
			.loadHandlers()
			.configureSubscriptions()
			.sendSubscriptions()

		return self
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

#Receive a msg, prep it, and handle any errors that may occur
# - Most of this should be queue independant
	def StartListeningToEndpoints
		log "Waiting for messages. To exit press CTRL+C"

		loop do
			retries = @config.maxRetries
			#Popping a msg off the queue should not be in the message handler, as it affects retry
			begin
    			log @stats.getForReporting
				job = @beanstalk.reserve @config.queueTimeout
				begin
					body = job.body
					@stats.incTotalProcessed
					@msg = YAML::load(body)
					if @msg.msg.class.name == "RServiceBus::Message_Subscription" then
						@subscriptionManager.add( @msg.msg.eventName, @msg.returnAddress )

					else
						self.HandleMessage()
						if !@config.forwardReceivedMessagesTo.nil? then
							self._SendAlreadyWrappedAndSerialised(body,@config.forwardReceivedMessagesTo)
						end
					end
					job.delete
		    	rescue Exception => e
					sleep 0.5
			    	retry if (retries -= 1) > 0		    	

					@stats.incTotalErrored
					if e.class.name == "Beanstalk::NotConnected" then
						puts "Lost connection to beanstalkd."
						puts "*** Start or Restart beanstalkd and try again."
						abort();
					end
				
					if e.class.name == "Redis::CannotConnectError" then
						puts "Lost connection to redis."
						puts "*** Start or Restart redis and try again."
						abort();
					end

					errorString = e.message + ". " + e.backtrace[0]
					if e.backtrace.length > 1 then
						errorString = errorString + ". " + e.backtrace[1]
					end
					if e.backtrace.length > 2 then
						errorString = errorString + ". " + e.backtrace[2]
					end
					log errorString

					@msg.addErrorMsg( @config.localQueueName, errorString )
					serialized_object = YAML::dump(@msg)
					self._SendAlreadyWrappedAndSerialised(serialized_object, @config.errorQueueName)
					job.delete
	    		end
	    	rescue Exception => e
	    		if e.message == "TIMED_OUT" then
	    		else
					puts "*** This is really unexpected."
			    	puts e.message
			    	puts e.backtrace
			    	abort()
		    	end
		    end
		end
	end

#Send the current msg to the appropriate handlers
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
						log e.message + ". " + e.backtrace[0]
						raise e
			   		end
		   		end
    	end
	end

#Sends a msg across the bus
#
# @param [String] serialized_object serialized RServiceBus::Message
# @param [String] queueName endpoint to which the msg will be sent
	def _SendAlreadyWrappedAndSerialised( serialized_object, queueName )
		log "Bus._SendAlreadyWrappedAndSerialised", true

		@beanstalk.use( queueName )
		@beanstalk.put( serialized_object )
	end

#Sends a msg across the bus
#
# @param [RServiceBus::Message] msg msg to be sent
# @param [String] queueName endpoint to which the msg will be sent
	def _SendNeedsWrapping( msg, queueName )
		log "Bus._SendNeedsWrapping", true

		rMsg = RServiceBus::Message.new( msg, @config.localQueueName )
		serialized_object = YAML::dump(rMsg)
		log "Sending: " + msg.class.name + " to: " + queueName, true
		self._SendAlreadyWrappedAndSerialised( serialized_object, queueName )
	end

#Sends a msg back across the bus
#Reply queues are specified in each msg. It works like
#email, where the reply address can actually be anywhere
#
# @param [RServiceBus::Message] msg msg to be sent
	def Reply( msg )
		log "Reply with: " + msg.class.name + " To: " + @msg.returnAddress, true
		@stats.incTotalReply

		self._SendNeedsWrapping( msg, @msg.returnAddress )
	end


#Send a msg across the bus
#msg destination is specified at the infrastructure level
#
# @param [RServiceBus::Message] msg msg to be sent
	def Send( msg )
		log "Bus.Send", true
		@stats.incTotalSent

		msgName = msg.class.name
		if !@config.messageEndpointMappings.has_key?( msgName ) then
			log "No end point mapping found for: " + msgName
			log "**** Check in RServiceBus.yml that the section MessageEndpointMappings contains an entry named : " + msgName
			raise "No end point mapping found for: " + msgName
		end

		queueName = @config.messageEndpointMappings[msgName]
		
		self._SendNeedsWrapping( msg, queueName )
	end

#Sends an event to all subscribers across the bus
#
# @param [RServiceBus::Message] msg msg to be sent
	def Publish( msg )
		log "Bus.Publish", true
		@stats.incTotalPublished

		subscriptions = @subscriptionManager.get(msg.class.name)
		subscriptions.each do |subscriber|
			self._SendNeedsWrapping( msg, subscriber )
		end

	end

#Sends a subscription request across the Bus
#
# @param [String] eventName event to be subscribes to
	def Subscribe( eventName )
		log "Bus.Subscribe: " + eventName, true


		queueName = @config.messageEndpointMappings[eventName]
		subscription = Message_Subscription.new( eventName )


		self._SendNeedsWrapping( subscription, queueName )
	end

end

end
