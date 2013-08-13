module RServiceBus
require 'beanstalk-client'

#A means for a stand-alone process to interact with the bus, without being a full
#rservicebus application
class Agent_Beanstalk
	@beanstalk
	
	def initialize(url=['localhost:11300'])
		@beanstalk = Beanstalk::Pool.new(url)
	end

# Put a msg on the bus
#
# @param [Object] messageObj The msg to be sent
# @param [String] queueName the name of the queue to be send the msg to
# @param [String] returnAddress the name of a queue to send replies to
	def sendMsg(messageObj, queueName, returnAddress=nil)
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

		@beanstalk.use( q )
		@beanstalk.put( serialized_object )
	end

# Gives an agent the means to receive a reply
#
# @param [String] queueName the name of the queue to monitor for messages
	def checkForReply( queueName )
		@beanstalk.watch queueName
		job = @beanstalk.reserve
		body = job.body
		job.delete

		@msg = YAML::load(body)
		return @msg.msg
	end
end

end
