module RServiceBus
    
    #Considered just holding in here when the circuit broke, but thought there may be other things the system might want
    # to do - not that I could think of anything off the top of my head.
    
    class MessageArrivedWhileCricuitBroken<StandardError
    end

    #An implementation of Michael Nygard's Circuit Breaker pattern.
    class CircuitBreaker

        def reset
            @broken = false

            @numberOfFailures = 0
            @timeOfFirstFailure = nil
            
            @timeToBreak = nil
            @timeToReset = nil
        end

        def initialize( host )
            @host = host
            @maxNumberOfFailures = RServiceBus.getValue( 'RSBCB_MAX', 5 )
            @secondsToBreak = RServiceBus.getValue( 'RSBCB_SECONDS_TO_BREAK', 60 ).to_i
            @secondsToReset = RServiceBus.getValue( 'RSBCB_SECONDS_TO_RESET', 60 ).to_i
            @resetOnSuccess = RServiceBus.getValue( 'RSBCB_RESET_ON_SUCCESS', false )
            
            self.reset
        end
        
        ####### Public Interface
        # Broken will be called before processing a message.
        #  => Broken will be called before Failure
        def Broken
            if !@timeToReset.nil? && Time.now > @timeToReset then
                self.reset
            end

            return @broken
        end

        def Live
            return !self.Broken
        end


## This should be called less than success.
## If there is a failure, then taking a bit longer gives time to settle.
        def Failure
            self.messageArrived


            ##logFirstFailure
            if @numberOfFailures == 0
                @numberOfFailures = 1
                @timeOfFirstFailure = Time.now
                @timeToBreak = @timeOfFirstFailure + @secondsToBreak
            else
                @numberOfFailures = @numberOfFailures + 1
            end


            ##checkToBreakCircuit
            if @numberOfFailures >= @maxNumberOfFailures then
                self.breakCircuit
            end
        end
        
        def Success
            if @resetOnSuccess == true then
                self.reset
                return
            end
            
            self.messageArrived
        end



        ######
        protected
        
        def messageArrived
            if !@timeToBreak.nil? && Time.now > @timeToBreak then
                self.reset
            end
            
            raise MessageArrivedWhileCricuitBroken if @broken == true
        end


        def breakCircuit
            @broken = true
            @timeToReset = Time.now + @secondsToReset
        end

    end
    
end
