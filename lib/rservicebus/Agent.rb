module RServiceBus

class QueueNotFoundForMsg<StandardError
end

    #A means for a stand-alone process to interact with the bus, without being a full
    #rservicebus application
    class Agent
        
        @mq

        def getAgent( uri )
            ENV["RSBMQ"] = uri.to_s

            RServiceBus.rlog "*** Agent.getAgent has been deprecated. Set the environment variable, RSBMQ, and simply create the class"
	    return Agent.new
        end
        
        def initialize
            @mq = MQ.get
        end
        
        # Put a msg on the bus
        #
        # @param [Object] messageObj The msg to be sent
        # @param [String] queueName the name of the queue to be send the msg to
        # @param [String] returnAddress the name of a queue to send replies to
        def sendMsg(messageObj, queueName, returnAddress=nil)
            raise QueueNotFoundForMsg.new( messageObj.class.name ) if queueName.nil?

            msg = RServiceBus::Message.new( messageObj, returnAddress )

            
            if queueName.index( "@" ).nil? then
                q = queueName
                else
                parts = queueName.split( "@" )
                msg.setRemoteQueueName( parts[0] )
                msg.setRemoteHostName( parts[1] )
                q = 'transport-out'
            end
            
            serialized_object = YAML::dump(msg)
            
            @mq.send( q, serialized_object )
        end
        
        # Gives an agent the means to receive a reply
        #
        # @param [String] queueName the name of the queue to monitor for messages
        def checkForReply( queueName )
            @mq.subscribe( queueName )
            body = @mq.pop
            @msg = YAML::load(body)
            @mq.ack
            return @msg.msg
        end

    end
end
