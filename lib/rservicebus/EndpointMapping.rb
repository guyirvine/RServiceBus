module RServiceBus
    
    #Marshals data for message end points
    #
    #Expected format;
    #	<msg mame 1>:<end point 1>;<msg mame 2>:<end point 2>
    class EndpointMapping
        
        def getValue( name )
            return RServiceBus.getValue( name )
        end
        
        def log( string, ver=false )
            RServiceBus.log( string )
        end
        
        def configureMapping( mapping )
            match = mapping.match( /(.+):(.+)/ )
            if match.nil? then
                log 'Mapping string provided is invalid'
                log "The entire mapping string is: #{mapping}"
                log "*** Could not find ':' in mapping entry, #{line}"
                exit()
            end
            
            RServiceBus.rlog "EndpointMapping.configureMapping: #{match[1]}, #{match[2]}"
            @endpoints[match[1]] = match[2]
            
            @queueNameList.each do |q|
                if q != match[2] && q.downcase == match[2].downcase then
                    log('*** Two queues specified with only case sensitive difference.')
                    log( "*** #{q} != #{match[2]}" )
                    log('*** If you meant these queues to be the same, please match case and restart the bus.')
                end
            end
            @queueNameList << match[2]
        end
        
        def Configure( localQueueName=nil )
            self.log('EndpointMapping.Configure')
            
            @queueNameList = []
            @queueNameList << localQueueName unless localQueueName.nil?

            unless self.getValue('MESSAGE_ENDPOINT_MAPPING').nil? then
              log('*** MESSAGE_ENDPOINT_MAPPING environment variable was detected')
              log("*** You may have intended MESSAGE_ENDPOINT_MAPPINGS, note the 'S' on the end")
            end
            
            mappings = self.getValue('MESSAGE_ENDPOINT_MAPPINGS')
            return self if mappings.nil?
            
            mappings.split(';').each do |mapping|
                self.configureMapping( mapping )
            end
            
            return self
        end
        
        def initialize
            @endpoints=Hash.new
        end
        
        def get( msgName )
            if @endpoints.has_key?( msgName ) then
                return @endpoints[msgName]
            end
            
            return nil;
        end
        
        def getSubscriptionEndpoints
            return @endpoints.keys.select { |el| el.end_with?('Event') }
        end
    end
    
end
