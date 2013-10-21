module RServiceBus
    
    require "rservicebus/MQ"
    require "redis"
    
    # Beanstalk client implementation.
    #
    class MQ_Redis<MQ
        
        # Connect to the broker
        #
        def connect( host, port )
            port ||= 6379
            string = "#{host}:#{port}"

            begin
                @redis = Redis.new(:host => host, :port => port)

                rescue Exception => e
                puts e.message
                puts "Error connecting to Redis for mq"
                puts "Host string, #{string}"
                abort()
            end
        end
        
        # Connect to the queue
        #
        def subscribe( queuename )
            @queuename = queuename
        end
        
        # Get next msg from queue
        def pop
                if @redis.llen( @queuename ) == 0 then
                    sleep @timeout
                    raise NoMsgToProcess.new
                end
                
                return @redis.lindex @queuename, 0
        end

        def returnToQueue
        end
        
        # "Commit" queue
        def ack
            @redis.lpop @queuename
        end

        # At least called in the Host rescue block, to ensure all network links are healthy
        def send( queueName, msg )
            @redis.rpush queueName, msg
        end

    end
end
