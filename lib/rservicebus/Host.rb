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
        
        @handlerList
        @resourceListByHandlerName
        
        @subscriptions
        
        @mq
        
        @appResources
        
        @config
        
        @subscriptionManager
        
        @stats
        
        
        @queueForMsgsToBeSentOnComplete
        
        
        #Provides a thin logging veneer
        #
        # @param [String] string Log entry
        # @param [Boolean] ver Indicator for a verbose log entry
        def log(string, ver=false)
            type = ver ? "VERB" : "INFO"
            if @config.verbose || !ver then
                timestamp = Time.new.strftime( "%Y-%m-%d %H:%M:%S" )
                puts "[#{type}] #{timestamp} :: #{string}"
            end
        end

        #Thin veneer for Configuring external resources
        #
        def configureAppResource
            @appResources = ConfigureAppResource.new.getResources( ENV, self )
            return self;
        end
        
        #Thin veneer for Configuring state
        #
        def configureStateManager
            @stateManager = StateManager.new
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
            @monitors = ConfigureMonitor.new( self, @appResources ).getMonitors( ENV )
            return self;
        end
        
        #Thin veneer for Configuring the Message Queue
        #
        def connectToMq
            @mq = ConfigureMQ.new.get( @config.mqHost + "/" + @config.localQueueName, @config.queueTimeout )
            
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
            @handlerManager = HandlerManager.new( self, @appResources, @stateManager )
            @handlerLoader = HandlerLoader.new( self, @handlerManager )
            
            @config.handlerPathList.each do |path|
                @handlerLoader.loadHandlersFromPath(path)
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
                log "Loaded Contract: #{path}", true
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
			.configureLogging()
			.loadHostSection()
			.configureMq()
			.loadContracts()
			.loadHandlerPathList()
            .loadLibs()
            .loadWorkingDirList();
            
            @endpointMapping = EndpointMapping.new.Configure( @config.localQueueName )
            
            self.configureStatistics()
            .loadContracts()
            .loadLibs()
			.configureAppResource()
            .configureStateManager()
            .configureCircuitBreaker()
			.configureMonitors()
			.loadHandlers()
            .configureCronManager()
			.connectToMq()
			.configureSubscriptions()
			.sendSubscriptions()

            
            return self
        end
        
        #Ignition
        #
        def run
            log "Starting the Host"
            
            log "Watching, #{@config.localQueueName}"
            $0 = "rservicebus - #{@config.localQueueName}"
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
                        elsif @msg.msg.class.name == "RServiceBus::Message_StatisticOutputOff" then
                            @stats.output = false
                        

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
                        
                        @msg.addErrorMsg( @config.localQueueName, e.message )
                        serialized_object = YAML::dump(@msg)
                        self._SendAlreadyWrappedAndSerialised(serialized_object, @config.errorQueueName)
                        @mq.ack

                        rescue NoHandlerFound => e
                        puts "*** Handler not found for msg, #{e.message}"
                        puts "*** Ensure a handler named, #{e.message}, is present in the MessageHandler directory."

                        @msg.addErrorMsg( @config.localQueueName, e.message )
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
                        
                        puts "*** Exception occured"
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
                            
                            @msg.addErrorMsg( @config.localQueueName, errorString )
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
                msgName = @msg.msg.class.name
                handlerList = @handlerManager.getHandlerListForMsg(msgName)
                
                log "Handler found for: " + msgName, true
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
                            log "An error occured in Handler: " + handler.class.name
                            raise e
                        end
                    end

                    @handlerManager.commitResourcesUsedToProcessMsg( msgName )
                    
                    self.sendQueuedMsgs
                    log "Finished processing msg, #{msgName}"
                    
                    rescue Exception => e
                    
                    @handlerManager.rollbackResourcesUsedToProcessMsg( msgName )
                    @queueForMsgsToBeSentOnComplete = nil
                    
                    raise e
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
                if queueName.index( "@" ).nil? then
                    q = queueName
                    log "Sending, #{msg.class.name} to, queueName", true
                    else
                    parts = queueName.split( "@" )
                    rMsg.setRemoteQueueName( parts[0] )
                    rMsg.setRemoteHostName( parts[1] )
                    q = 'transport-out'
                    log "Sending, #{msg.class.name} to, queueName, via #{q}", true
                end

                serialized_object = YAML::dump(rMsg)
                self._SendAlreadyWrappedAndSerialised( serialized_object, q )
            end

            def sendQueuedMsgs
                @queueForMsgsToBeSentOnComplete.each do |row|
                    self._SendNeedsWrapping( row["msg"], row["queueName"] )
                end
            end
            
            def queueMsgForSendOnComplete( msg, queueName )
                @queueForMsgsToBeSentOnComplete << Hash["msg", msg, "queueName", queueName]
            end
            
            #Sends a msg back across the bus
            #Reply queues are specified in each msg. It works like
            #email, where the reply address can actually be anywhere
            #
            # @param [RServiceBus::Message] msg msg to be sent
            def Reply( msg )
                log "Reply with: " + msg.class.name + " To: " + @msg.returnAddress, true
                @stats.incTotalReply

                self.queueMsgForSendOnComplete( msg, @msg.returnAddress )
            end
            
            def getEndpointForMsg( msgName )
                queueName = @endpointMapping.get( msgName )
                return queueName unless queueName.nil?
                
                return @config.localQueueName if @handlerManager.canMsgBeHandledLocally(msgName)
                
                log "No end point mapping found for: " + msgName
                log "**** Check environment variable MessageEndpointMappings contains an entry named : " + msgName
                raise "No end point mapping found for: " + msgName
            end


            #Send a msg across the bus
            #msg destination is specified at the infrastructure level
            #
            # @param [RServiceBus::Message] msg msg to be sent
            def Send( msg )
                log "Bus.Send", true
                @stats.incTotalSent
                
                msgName = msg.class.name
                queueName = self.getEndpointForMsg( msgName )
                
                self.queueMsgForSendOnComplete( msg, queueName )
            end
            
            #Sends an event to all subscribers across the bus
            #
            # @param [RServiceBus::Message] msg msg to be sent
            def Publish( msg )
                log "Bus.Publish", true
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
                log "Bus.Subscribe: " + eventName, true

                queueName = self.getEndpointForMsg( eventName )
                subscription = Message_Subscription.new( eventName )
                
                self._SendNeedsWrapping( subscription, queueName )
            end
            
        end
        
    end
