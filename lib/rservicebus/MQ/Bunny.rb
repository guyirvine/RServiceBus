module RServiceBus
    
    require "bunny"
    require "rservicebus/MQ"
    
    # RabbitMQ client implementation.
    #
    class MQ_Bunny<MQ
        @uri
        
        # Connect to the broker
        #
        def connect( host, port )
            port ||= 5672
            
            @bunny = Bunny.new(:host=>host, :port=>port)
            @bunny.start
            @pop_exch = @bunny.exchange('rservicebus.pop')
            @send_exch = @bunny.exchange('rservicebus.send')
        end

        # Connect to the queue
        #
        def subscribe( queueName )
            @queue = @bunny.queue( queueName )
            @queue.bind( @pop_exch );
        end

        # Get next msg from queue
        def pop
            msg = @queue.pop(:ack => true)[:payload]

            if msg == :queue_empty then
                raise NoMsgToProcess.new
            end

            return msg
        end
        
        # "Commit" the pop to the queue
        def ack
            @queue.ack
        end

        # Send a msg to a queue
        def send( queueName, msg )
            queue = @bunny.queue(queueName)
            queue.bind(@send_exch)
            @send_exch.publish(msg)
            queue.unbind(@send_exch)
        end
        
    end
end
