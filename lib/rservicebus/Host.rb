module RServiceBus
    
    
    class NoMsgToProcess<StandardError
    end
    
    #Host process for rservicebus
    class Host

        @handlerList
        @resourceByHandlerNameList

        @subscriptions

        @mq

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

        def connectToMq
            @mq = ConfigureMQ.new.get( @config.mqHost + "/" + @config.localQueueName, @config.queueTimeout )

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
            @resourceByHandlerNameList = handlerLoader.resourceList
            
            return self
        end
        
        def loadContracts()
            log "Load Contracts"
            
            @config.contractList.each do |path|
                require path
            end
            
            return self
        end
        
        def loadLibs()
            log "Load Libs"
            
            @config.libList.each do |path|
                if Dir.exists?( path ) then
                    path = path.strip.chomp( "/" )
                    path = path + "/**/*.rb"
                end
                Dir.glob( path ).each do |path|
                    require path
                end
            end
            
            return self
        end
        
        def configureSubscriptions
            subscriptionStorage = ConfigureSubscriptionStorage.new.get( @config.appName, @config.subscriptionUri )
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
			.configureMq()
			.loadContracts()
			.loadMessageEndpointMappings()
			.loadHandlerPathList()
            .loadLibs()
            .loadWorkingDirList();

            self.configureStatistics()
			.configureAppResource()
			.connectToMq()
			.loadHandlers()
            .loadContracts()
            .loadLibs()
			.configureSubscriptions()
			.sendSubscriptions()
            
            return self
        end
        
        def run
            log "Starting the Host"
            
            log "Watching, " + @config.localQueueName
            if !@config.forwardReceivedMessagesTo.nil? then
                log "Forwarding all received messages to: " + @config.forwardReceivedMessagesTo.to_s
            end
            
            self.StartListeningToEndpoints
        end
        
        #Receive a msg, prep it, and handle any errors that may occur
        # - Most of this should be queue independant
        def StartListeningToEndpoints
            log "Waiting for messages. To exit press CTRL+C"
            statOutputCountdown = 0
            messageLoop = true

            while messageLoop do
                retries = @config.maxRetries
                #Popping a msg off the queue should not be in the message handler, as it affects retry
                begin
                    if statOutputCountdown == 0 then
                        #                        log @stats.getForReporting
                        statOutputCountdown = @config.statOutputCountdown-1
                        else
                        statOutputCountdown = statOutputCountdown - 1
                    end
                    body = @mq.pop
                    begin
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
                        @mq.ack
                        rescue Exception => e
                        sleep 0.5

                        puts e.message
                        puts e.backtrace
                        
                        @handlerList[@msg.msg.class.name].each do |handler|
                            @resourceByHandlerNameList[handler.class.name].each do |resource|
                                resource.reconnect
                            end
                        end
                        
                        
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
                        
                        errorString = e.message + ". " + e.backtrace.join( ". " )
                        log errorString
                        
                        @msg.addErrorMsg( @config.localQueueName, errorString )
                        serialized_object = YAML::dump(@msg)
                        self._SendAlreadyWrappedAndSerialised(serialized_object, @config.errorQueueName)
                        @mq.ack
                    end
                    rescue SystemExit, Interrupt
                    puts "Exiting on request ..."
                    messageLoop = false

                    rescue NoMsgToProcess => e
                    #This exception is just saying there are no messages to process
                    statOutputCountdown = 0
                    rescue Exception => e
                    if e.message == "SIGTERM" then
                    puts "Exiting on request ..."
                    messageLoop = false
                    else
                    puts "*** This is really unexpected."
                    messageLoop = false
                    puts "Message: " + e.message
                    puts e.backtrace
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
                puts "No handler found for: " + msgName
                puts YAML::dump(@msg)
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
            
            if !@config.forwardSentMessagesTo.nil? then
                @mq.send( @config.forwardSentMessagesTo, serialized_object )
            end
            
            @mq.send( queueName, serialized_object )
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
