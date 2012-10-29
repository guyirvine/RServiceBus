module RServiceBus
    
    require "uri"
    
    # Wrapper base class for resources used by applications, allowing rservicebus to configure the resource
    # - dependency injection.
    #
    class AppResource
        @uri
        
        # The method which actually connects to the resource.
        #
        def connect(uri)
            raise "Method, connect, needs to be implemented for resource"
        end

        def _connect
            self.connect(@uri)
            puts "#{self.class.name}. Connected to, #{@uri.to_s}" unless !ENV["QUIET"].nil?
        end

        # Resources are attached resources, and can be specified using the URI syntax.
        #
        # @param [String] uri a location for the resource to which we will attach, eg redis://127.0.0.1/foo
        def initialize( uri )
            @uri = uri
            self._connect
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
                rescue
                puts "AppResource. An error was raised while closing connection to, " + @uri.to_s
            end

            self._connect
        end
        
    end
end
