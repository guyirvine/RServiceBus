module RServiceBus
    
    
    class NoHandlerFound<StandardError
    end
    class ClassNotFoundForMsg<StandardError
    end
    class NoMsgToProcess<StandardError
    end
    class PropertyNotSet<StandardError
    end
    
    #Host process for rservicebus
    class Host
        attr_accessor :sagaData
        
        @sagaData
        
        @handlerList
        @resourceListByHandlerName
        
        @subscriptions
        
        @mq
        
        @resourceManager
        
        @config
        
        @subscriptionManager
        
        @stats
        
        
        @queueForMsgsToBeSentOnComplete


        #Provides a thin logging veneer
        #
        # @param [String] string Log entry
        # @param [Boolean] ver Indicator for a verbose log entry
        def log(string, ver=false)
            RServiceBus.log( string, ver )
        end
        
        #Thin veneer for Configuring external resources
        #
        def configureAppResource
            @resourceManager = ConfigureAppResource.new.getResources( ENV, self, @stateManager, @sagaStorage )
            return self;
        end
        
        #Thin veneer for Configuring state
        #
        def configureStateManager
            @stateManager = StateManager.new
            return self;
        end
        
        #Thin veneer for Configuring state
        #
        def configureSagaStorage
            string = RServiceBus.getValue( "SAGA_URI" )
            if string.nil? then
                string = "dir:///tmp"
            end
            
            uri = URI.parse( string )
            @sagaStorage = SagaStorage.Get( uri )
            return self;
        end
        
        #Thin veneer for Configuring Cron
        #
        def configureCircuitBreaker
            @circuitBreaker = CircuitBreaker.new( self )
            return self;
        end
        
        
        #Thin veneer for Configuring external resources
        #
        def configureMonitors
            @monitors = ConfigureMonitor.new( self, @resourceManager ).getMonitors( ENV )
            return self;
        end
        
        #Thin veneer for Configuring the Message Queue
        #
        def connectToMq
            @mq = MQ.get
            
            return self
        end
        
        #Subscriptions are specified by adding events to the
        #msg endpoint mapping
        def sendSubscriptions
            log "Send Subscriptions"
            
            @endpointMapping.getSubscriptionEndpoints.each { |eventName| self.Subscribe( eventName ) }
            
            return self
        end
        
        #Load and configure Message Handlers
        #
        def loadHandlers()
            log "Load Message Handlers"
            @handlerManager = HandlerManager.new( self, @resourceManager, @stateManager )
            @handlerLoader = HandlerLoader.new( self, @handlerManager )
            
            @config.handlerPathList.each do |path|
                @handlerLoader.loadHandlersFromPath(path)
            end
            
            return self
        end
        
        #Load and configure Sagas
        def loadSagas()
            log "Load Sagas"
            @sagaManager = Saga_Manager.new( self, @resourceManager, @sagaStorage )
            @sagaLoader = SagaLoader.new( self, @sagaManager )
            
            @config.sagaPathList.each do |path|
                @sagaLoader.loadSagasFromPath(path)
            end
            
            return self
        end
        
        #Thin veneer for Configuring Cron
        #
        def configureCronManager
            @cronManager = CronManager.new( self, @handlerManager.getListOfMsgNames )
            return self;
        end
        
        #Load Contracts
        #
        def loadContracts()
            log "Load Contracts"
            
            @config.contractList.each do |path|
                require path
                RServiceBus.rlog "Loaded Contract: #{path}"
            end
            
            return self
        end
        
        #For each directory given, find and load all librarys
        #
        def loadLibs()
            log "Load Libs"
            
            @config.libList.each do |path|
                $:.unshift path
            end
            
            return self
        end
        
        #Load, configure and initialise Subscriptions
        #
        def configureSubscriptions
            subscriptionStorage = ConfigureSubscriptionStorage.new.get( @config.appName, @config.subscriptionUri )
            @subscriptionManager = SubscriptionManager.new( subscriptionStorage )
            
            return self
        end
        
        #Initialise statistics monitor
        #
        def configureStatistics
            @stats = StatisticManager.new( self )
            
            return self
        end
        
        def initialize()
            @config = ConfigFromEnv.new
			.loadHostSection()
			.loadContracts()
			.loadHandlerPathList()
            .loadSagaPathList()
            .loadLibs()
            .loadWorkingDirList();
            
            self.connectToMq()
            
            @endpointMapping = EndpointMapping.new.Configure( @mq.localQueueName )
            
            self.configureStatistics()
            .loadContracts()
            .loadLibs()
            .configureStateManager()
            .configureSagaStorage()
			.configureAppResource()
            .configureCircuitBreaker()
			.configureMonitors()
			.loadHandlers()
            .loadSagas()
            .configureCronManager()
			.configureSubscriptions()
			.sendSubscriptions()
            
            
            return self
        end
        
        #Ignition
        #
        def run
            log "Starting the Host"
            
            log "Watching, #{@mq.localQueueName}"
            $0 = "rservicebus - #{@mq.localQueueName}"
            if !@config.forwardReceivedMessagesTo.nil? then
                log "Forwarding all received messages to: " + @config.forwardReceivedMessagesTo.to_s
            end
            if !@config.forwardSentMessagesTo.nil? then
                log "Forwarding all sent messages to: " + @config.forwardSentMessagesTo.to_s
            end
            
            self.StartListeningToEndpoints
        end
        
        #Receive a msg, prep it, and handle any errors that may occur
        # - Most of this should be queue independant
        def StartListeningToEndpoints
            log "Waiting for messages. To exit press CTRL+C"
            #            statOutputCountdown = 0
            messageLoop = true
            retries = @config.maxRetries
            
            while messageLoop do
                #Popping a msg off the queue should not be in the message handler, as it affects retry
                begin
                    @stats.tick
                    
                    if @circuitBreaker.Broken then
                        sleep 0.5
                        next
                    end
                    
                    body = @mq.pop
                    begin
                        @stats.incTotalProcessed
                        @msg = YAML::load(body)
                        if @msg.msg.class.name == "RServiceBus::Message_Subscription" then
                            @subscriptionManager.add( @msg.msg.eventName, @msg.returnAddress )
                            elsif @msg.msg.class.name == "RServiceBus::Message_StatisticOutputOn" then
                            @stats.output = true
                            log "Turn on Stats logging"
                            elsif @msg.msg.class.name == "RServiceBus::Message_StatisticOutputOff" then
                            @stats.output = false
                            log "Turn off Stats logging"
                            elsif @msg.msg.class.name == "RServiceBus::Message_VerboseOutputOn" then
                            ENV["VERBOSE"] = "true"
                            log "Turn on Verbose logging"
                            elsif @msg.msg.class.name == "RServiceBus::Message_VerboseOutputOff" then
                            ENV.delete( "VERBOSE" )
                            log "Turn off Verbose logging"
                            
                            
                            else
                            
                            self.HandleMessage()
                            
                            if !@config.forwardReceivedMessagesTo.nil? then
                                self._SendAlreadyWrappedAndSerialised(body,@config.forwardReceivedMessagesTo)
                            end
                        end
                        @mq.ack
                        rescue ClassNotFoundForMsg => e
                        puts "*** Class not found for msg, #{e.message}"
                        puts "*** Ensure, #{e.message}, is defined in Contract.rb, most likely as 'Class #{e.message} end"
                        
                        @msg.addErrorMsg( @mq.localQueueName, e.message )
                        serialized_object = YAML::dump(@msg)
                        self._SendAlreadyWrappedAndSerialised(serialized_object, @config.errorQueueName)
                        @mq.ack
                        
                        rescue NoHandlerFound => e
                        puts "*** Handler not found for msg, #{e.message}"
                        puts "*** Ensure a handler named, #{e.message}, is present in the MessageHandler directory."
                        
                        @msg.addErrorMsg( @mq.localQueueName, e.message )
                        serialized_object = YAML::dump(@msg)
                        self._SendAlreadyWrappedAndSerialised(serialized_object, @config.errorQueueName)
                        @mq.ack
                        
                        rescue PropertyNotSet => e
                        #This has been re-rasied from a rescue in the handler
                        puts "*** #{e.message}"
                        #"Property, #{e.message}, not set for, #{handler.class.name}"
                        propertyName = e.message[10, e.message.index(",", 10)-10]
                        puts "*** Ensure the environemnt variable, RSB_#{propertyName}, has been set at startup."
                        
                        rescue Exception => e
                        sleep 0.5
                        
                        puts "*** Exception occurred"
                        puts e.message
                        puts e.backtrace
                        puts "***"
                        
                        if retries > 0 then
                            retries = retries - 1
                            @mq.returnToQueue
                            else
                            
                            @circuitBreaker.Failure
                            
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
                            #                            log errorString
                            
                            @msg.addErrorMsg( @mq.localQueueName, errorString )
                            serialized_object = YAML::dump(@msg)
                            self._SendAlreadyWrappedAndSerialised(serialized_object, @config.errorQueueName)
                            @mq.ack
                            retries = @config.maxRetries
                        end
                    end
                    rescue SystemExit, Interrupt
                    puts "Exiting on request ..."
                    messageLoop = false
                    
                    rescue NoMsgToProcess => e
                    #This exception is just saying there are no messages to process
                    statOutputCountdown = 0
                    @queueForMsgsToBeSentOnComplete = Array.new
                    @monitors.each do |o|
                        o.Look
                    end
                    self.sendQueuedMsgs
                    @queueForMsgsToBeSentOnComplete = nil
                    
                    @queueForMsgsToBeSentOnComplete = Array.new
                    @cronManager.Run
                    self.sendQueuedMsgs
                    @queueForMsgsToBeSentOnComplete = nil
                    
                    
                    @circuitBreaker.Success
                    
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
            #
            def HandleMessage()
                @resourceManager.Begin
                msgName = @msg.msg.class.name
                handlerList = @handlerManager.getHandlerListForMsg(msgName)
                
                
                RServiceBus.rlog "Handler found for: " + msgName
                begin
                    @queueForMsgsToBeSentOnComplete = Array.new
                    
                    log "Started processing msg, #{msgName}"
                    handlerList.each do |handler|
                        begin
                            log "Handler, #{handler.class.name}, Started"
                            handler.Handle( @msg.msg )
                            log "Handler, #{handler.class.name}, Finished"
                            rescue PropertyNotSet => e
                            raise PropertyNotSet.new( "Property, #{e.message}, not set for, #{handler.class.name}" )
                            rescue Exception => e
                            puts "E #{e.message}"
                            log "An error occurred in Handler: " + handler.class.name
                            raise e
                        end
                    end
                    
                    
                    if @sagaManager.Handle( @msg ) == false then
                        raise NoHandlerFound.new( msgName ) if handlerList.length == 0
                    end
                    
                    
                    
                    @resourceManager.Commit( msgName )
                    
                    self.sendQueuedMsgs
                    log "Finished processing msg, #{msgName}"
                    
                    rescue Exception => e
                    
                    @resourceManager.Rollback( msgName )
                    @queueForMsgsToBeSentOnComplete = nil
                    
                    raise e
                end
            end
            
            #######################################################################################################
            # All msg sending Methods
            
            #Sends a msg across the bus
            #
            # @param [String] serialized_object serialized RServiceBus::Message
            # @param [String] queueName endpoint to which the msg will be sent
            def _SendAlreadyWrappedAndSerialised( serialized_object, queueName )
                RServiceBus.rlog "Bus._SendAlreadyWrappedAndSerialised"
                
                if !@config.forwardSentMessagesTo.nil? then
                    @mq.send( @config.forwardSentMessagesTo, serialized_object )
                end
                
                @mq.send( queueName, serialized_object )
            end
            
            #Sends a msg across the bus
            #
            # @param [RServiceBus::Message] msg msg to be sent
            # @param [String] queueName endpoint to which the msg will be sent
            def _SendNeedsWrapping( msg, queueName, correlationId )
                RServiceBus.rlog "Bus._SendNeedsWrapping"
                
                rMsg = RServiceBus::Message.new( msg, @mq.localQueueName, correlationId )
                if queueName.index( "@" ).nil? then
                    q = queueName
                    RServiceBus.rlog "Sending, #{msg.class.name} to, queueName"
                    else
                    parts = queueName.split( "@" )
                    rMsg.setRemoteQueueName( parts[0] )
                    rMsg.setRemoteHostName( parts[1] )
                    q = 'transport-out'
                    RServiceBus.rlog "Sending, #{msg.class.name} to, #{queueName}, via #{q}"
                end
                
                serialized_object = YAML::dump(rMsg)
                self._SendAlreadyWrappedAndSerialised( serialized_object, q )
            end
            
            def sendQueuedMsgs
                @queueForMsgsToBeSentOnComplete.each do |row|
                    self._SendNeedsWrapping( row["msg"], row["queueName"], row["correlationId"] )
                end
            end
            
            def queueMsgForSendOnComplete( msg, queueName )
                correlationId = sagaData.nil? ? nil : sagaData.correlationId
                correlationId = @msg.correlationId.nil? ? correlationId : @msg.correlationId
                @queueForMsgsToBeSentOnComplete << Hash["msg", msg, "queueName", queueName, "correlationId", correlationId]
            end
            
            #Sends a msg back across the bus
            #Reply queues are specified in each msg. It works like
            #email, where the reply address can actually be anywhere
            #
            # @param [RServiceBus::Message] msg msg to be sent
            def Reply( msg )
                RServiceBus.rlog "Reply with: " + msg.class.name + " To: " + @msg.returnAddress
                @stats.incTotalReply
                
                self.queueMsgForSendOnComplete( msg, @msg.returnAddress )
            end
            
            def getEndpointForMsg( msgName )
                queueName = @endpointMapping.get( msgName )
                return queueName unless queueName.nil?
                
                return @mq.localQueueName if @handlerManager.canMsgBeHandledLocally(msgName)
                
                log "No end point mapping found for: " + msgName
                log "**** Check environment variable MessageEndpointMappings contains an entry named : " + msgName
                raise "No end point mapping found for: " + msgName
            end
            
            
            #Send a msg across the bus
            #msg destination is specified at the infrastructure level
            #
            # @param [RServiceBus::Message] msg msg to be sent
            def Send( msg )
                RServiceBus.rlog "Bus.Send"
                @stats.incTotalSent
                
                msgName = msg.class.name
                queueName = self.getEndpointForMsg( msgName )
                
                self.queueMsgForSendOnComplete( msg, queueName )
            end
            
            #Sends an event to all subscribers across the bus
            #
            # @param [RServiceBus::Message] msg msg to be sent
            def Publish( msg )
                RServiceBus.rlog "Bus.Publish"
                @stats.incTotalPublished
                
                subscriptions = @subscriptionManager.get(msg.class.name)
                subscriptions.each do |subscriber|
                    self.queueMsgForSendOnComplete( msg, subscriber )
                end
                
            end
            
            #Sends a subscription request across the Bus
            #
            # @param [String] eventName event to be subscribes to
            def Subscribe( eventName )
                RServiceBus.rlog "Bus.Subscribe: " + eventName
                
                queueName = self.getEndpointForMsg( eventName )
                subscription = Message_Subscription.new( eventName )
                
                self._SendNeedsWrapping( subscription, queueName )
            end
            
        end
        
    end
