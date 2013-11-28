module RServiceBus
    
    require "bunny"
    require "rservicebus/MQ"
    
    # Beanstalk client implementation.
    #
    class MQ_RabbitMq<MQ
        
        # Connect to the broker
        #
        def connect( host, port )
            port ||= 11300
            string = "#{host}:#{port}"

            begin
                
                @conn = Bunny.new
                @conn.start

                @ch = @conn.create_channel
                @x = @ch.default_exchange

                rescue Exception => e
                puts "Error connecting to Beanstalk"
                puts "Host string, #{string}"
                if e.message == "Beanstalk::NotConnected" then
                    puts "***Most likely, beanstalk is not running. Start beanstalk, and try running this again."
                    puts "***If you still get this error, check beanstalk is running at, #{string}"
                    else
                    puts e.message
                    puts e.backtrace
                end
                abort()
            end
        end
        
        # Connect to the queue
        #
        def subscribe( queuename )
            @q  = @ch.queue( queuename, :durable => true, :auto_delete => false)
        end

        # Get next msg from queue
        def pop
            begin
                @delivery_info, @properties, @payload = @q.pop(:ack => true)
                
                if @delivery_info.nil? then
                    sleep @timeout
                    raise NoMsgToProcess.new
                end

            end
            return @payload
        end

        def returnToQueue
            @ch.reject( @delivery_info.delivery_tag, true )
        end

        # "Commit" queue
        def ack
            @ch.ack( @delivery_info.delivery_tag )
            @delivery_info = nil
            @properties = nil
            @payload = nil
        end

        # At least called in the Host rescue block, to ensure all network links are healthy
        def send( queueName, msg )
            @x.publish(msg, :routing_key => queueName)
        end

    end
end
