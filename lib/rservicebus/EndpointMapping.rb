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
                log "Mapping string provided is invalid"
                log "The entire mapping string is: #{mapping}"
                log "*** Could not find ':' in mapping entry, #{line}"
                exit()
            end
            
            self.log( "EndpointMapping.configureMapping: #{match[1]}, #{match[2]}", true )
            @endpoints[match[1]] = match[2]

        end
        
        def Configure
            self.log( "EndpointMapping.Configure" )
            mappings = self.getValue( "MESSAGE_ENDPOINT_MAPPINGS" )
            return self if mappings.nil?

            mappings.split( ";" ).each do |mapping|
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
            return @endpoints.keys.select { |el| el.end_with?( "Event" ) }
        end
    end
    
end
