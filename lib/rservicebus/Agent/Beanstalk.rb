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
		serialized_object = YAML::dump(msg)

		@beanstalk.use( queueName )
		@beanstalk.put( serialized_object )
	end

# Gives an agent a mean to receive replies
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