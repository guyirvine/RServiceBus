module RServiceBus
    
    require "uri"
    
    # Wrapper base class for resources used by applications, allowing rservicebus to configure the resource
    # - dependency injection.
    #
    class AppResource
        @uri
        @connection

        # The method which actually connects to the resource.
        #
        def connect(uri)
            raise "Method, connect, needs to be implemented for resource"
        end

        def _connect
            @connection = self.connect(@uri)
            @host.log "#{self.class.name}. Connected to, #{@uri.to_s}", true
        end

        # Resources are attached resources, and can be specified using the URI syntax.
        #
        # @param [String] uri a location for the resource to which we will attach, eg redis://127.0.0.1/foo
        def initialize( host, uri )
            @host = host
            @uri = uri
            #Do a connect / disconnect loop on startup to validate the connection
            self._connect
            self.finished
        end

        # The method which actually configures the resource.
        #
        # @return [Object] the configured object.
        def getResource
            return @connection
        end

        # A notification that ocurs after getResource, to allow cleanup
        def finished
            @connection.close
        end

        # At least called in the Host rescue block, to ensure all network links are healthy
        def reconnect
            begin
                self.finished
                rescue Exception => e
                puts "** AppResource. An error was raised while closing connection to, " + @uri.to_s
                puts "Message: " + e.message
                puts e.backtrace
            end

            self._connect
        end
        
        # Transaction Semantics
        def Begin
            
        end
        
        # Transaction Semantics
        def Commit
            
        end

        # Transaction Semantics
        def Rollback
            
        end
        
    end
end
