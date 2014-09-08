module RServiceBus
    
    class Monitor
        
        attr_accessor :Bus
        
        @Bus
        @uri
        @connection
        @MsgType
        
        # The method which actually connects to the resource.
        #
        def connect(uri)
            raise 'Method, connect, needs to be implemented for resource'
        end
        
        # The method which actually connects to the resource.
        #
        def Look
            raise 'Method, Look, needs to be implemented for the Monitor'
        end
        
        def _connect
            @connection = self.connect(@uri)
            @Bus.log "#{self.class.name}. Connected to, #{@uri.to_s}" if ENV['QUIET'].nil?
        end
        
        # Resources are attached resources, and can be specified using the URI syntax.
        #
        # @param [String] uri a location for the resource to which we will attach, eg redis://127.0.0.1/foo
        def initialize( bus, name, uri )
            @Bus = bus
            #        @MsgType = Object.const_get( name )
            newAnonymousClass = Class.new(Monitor_Message)
            Object.const_set( name, newAnonymousClass )
            @MsgType = Object.const_get( name )
            
            @uri = uri
            self._connect
        end

        # A notification that allows cleanup
        def finished
        end
        
        # At least called in the Host rescue block, to ensure all network links are healthy
        def reconnect
            begin
                self.finished
                rescue Exception => e
                puts '** Monitor. An error was raised while closing connection to, ' + @uri.to_s
                puts 'Message: ' + e.message
                puts e.backtrace
            end
            
            self._connect
        end
        
        def send( payload, uri )
            msg = @MsgType.new( payload, uri )
            
            @Bus.Send( msg )
        end
    end
end
