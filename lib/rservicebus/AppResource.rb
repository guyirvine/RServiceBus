module RServiceBus
    
    require "uri"
    
    # Wrapper base class for resources used by applications, allowing rservicebus to configure the resource
    # - dependency injection.
    #
    class AppResource
        @uri
        
        # Resources are attached resources, and can be specified using the URI syntax.
        #
        # @param [String] uri a location for the resource to which we will attach, eg redis://127.0.0.1/foo
        def initialize( uri )
            @uri = uri
        end
        
        # The method which actually configures the resource.
        #
        # @return [Object] the configured object.
        def getResource
            raise "Method, getResource, needs to be implemented for resource"
        end
        
        # A notification that ocurs after getResource, to allow cleanup
        def finished
            raise "Method, getResource, needs to be implemented for resource"
        end
        
        # At least called in the Host rescue block, to ensure all network links are healthy
        def reconnect
            begin
                @connection.close
                rescue
                puts "AppResource. An error was raised while closing connection to, " + @uri.to_s
            end
            
            self.connect
        end
        
    end
end
