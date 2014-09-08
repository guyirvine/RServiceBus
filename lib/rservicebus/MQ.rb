module RServiceBus
    
    require 'uri'
    
    class JobTooBigError<StandardError
    end
    
    # Wrapper base class for Queue implementations available to the applications, allowing rservicebus to instatiate and configure
    # queue implementations at startup
    # - dependency injection.
    #
    class MQ
        
        attr_reader :localQueueName
        
        @uri
        
        
        def MQ.get
            mqString = RServiceBus.getValue( 'RSBMQ', 'beanstalk://localhost');
            uri = URI.parse( mqString )
            
            case uri.scheme
                when 'beanstalk'
                require 'rservicebus/MQ/Beanstalk'
                mq = MQ_Beanstalk.new( uri )
                
                when 'redis'
                require 'rservicebus/MQ/Redis'
                mq = MQ_Redis.new( uri )
                
                when 'rabbitmq'
                require 'rservicebus/MQ/RabbitMq'
                mq = MQ_RabbitMq.new( uri )

                else
                abort("Scheme, #{uri.scheme}, not recognised when configuring mq, #{string}");
            end
            
            return mq
        end
        
        # Resources are attached resources, and can be specified using the URI syntax.
        #
        # @param [URI] uri the type and location of queue, eg beanstalk://127.0.0.1/foo
        # @param [Integer] timeout the amount of time to wait for a msg to arrive
        def initialize( uri )
            
            if uri.is_a? URI then
                @uri = uri
                else
                puts 'uri must be a valid URI'
                abort()
            end

            if uri.path == '' || uri.path == '/' then
                @localQueueName = RServiceBus.getValue( 'APPNAME', 'RServiceBus')
                else
                @localQueueName = uri.path
                @localQueueName[0] = ''
            end

            if @localQueueName == '' then
                puts "@localQueueName: #{@localQueueName}"
                puts 'Queue name must be supplied '
                puts "*** uri, #{uri}, needs to contain a queue name"
                puts '*** the structure is scheme://host[:port]/queuename'
                abort()
            end
            
            @timeout = RServiceBus.getValue( 'QUEUE_TIMEOUT', '5').to_i
            self.connect(uri.host, uri.port)
            self.subscribe( @localQueueName )
        end
        
        # Connect to the broker
        #
        # @param [String] host machine runnig the mq
        # @param [String] port port the mq is running on
        def connect( host, port )
            raise 'Method, connect, needs to be implemented'
        end
        
        # Connect to the receiving queue
        #
        # @param [String] queuename name of the receiving queue
        def subscribe( queuename )
            raise 'Method, subscribe, needs to be implemented'
        end
        
        # Get next msg from queue
        def pop
            raise 'Method, pop, needs to be implemented'
        end
        
        # "Commit" the pop
        def ack
            raise 'Method, ack, needs to be implemented'
        end
        
        # At least called in the Host rescue block, to ensure all network links are healthy
        #
        # @param [String] queueName name of the queue to which the m sg should be sent
        # @param [String] msg msg to be sent
        def send( queueName, msg )
            begin
                @connection.close
                rescue
                puts 'AppResource. An error was raised while closing connection to, ' + @uri.to_s
            end
            
        end
        
    end
end
