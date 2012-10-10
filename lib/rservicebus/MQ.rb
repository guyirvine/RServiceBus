module RServiceBus
    
    require "uri"
    
    # Wrapper base class for Queue implementations available to the applications, allowing rservicebus to instatiate and configure
    # queue implementations at startup
    # - dependency injection.
    #
    class MQ
        @uri
        
        # Resources are attached resources, and can be specified using the URI syntax.
        #
        # @param [URI] uri the type and location of queue, eg bunny://127.0.0.1/foo
        # @param [Integer] timeout the amount of time to wait for a msg to arrive
        def initialize( uri, timeout )
            @timeout = timeout
            if uri.is_a? URI then
                @uri = uri
                else
                puts "uri must be a valid URI"
                abort()
            end
            
            host = uri.host
            port = uri.port
            queue = uri.path.sub( "/", "" )
            
            if ( queue == "" )
                puts "Queue name must be supplied "
                puts "*** uri, #{uri}, needs to contain a queue name"
                puts "*** the structure is scheme://host[:port]/queuename"
                abort()
            end

            self.connect(uri.host, uri.port)
            self.subscribe( queue )
        end
        
        # Connect to the broker
        #
        def connect( host, port )
            raise "Method, connect, needs to be implemented"
        end
        
        # Connect to the queue
        #
        def subscribe( queuename )
            raise "Method, subscribe, needs to be implemented"
        end
        
        # Get next msg from queue
        def pop
            raise "Method, pop, needs to be implemented"
        end
        
        # "Commit" queue
        def ack
            raise "Method, ack, needs to be implemented"
        end
        
        # At least called in the Host rescue block, to ensure all network links are healthy
        def send( queueName, msg )
            begin
                @connection.close
                rescue
                puts "AppResource. An error was raised while closing connection to, " + @uri.to_s
            end
            
        end
        
    end
end
