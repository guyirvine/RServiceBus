module RServiceBus
require 'bunny'

#A means for a stand-alone process to interact with the bus, without being a full
#rservicebus application
class Agent_Bunny
	@bunny

	def initialize(host='localhost')
		@bunny = Bunny.new(:host=>host)
        @bunny.start
        @direct_exchange = @bunny.exchange('rservicebus.agent')
	end

# Put a msg on the bus
#
# @param [Object] messageObj The msg to be sent
# @param [String] queueName the name of the queue to be send the msg to
# @param [String] returnAddress the name of a queue to send replies to
	def sendMsg(messageObj, queueName, returnAddress=nil)
		msg = RServiceBus::Message.new( messageObj, returnAddress )
		serialized_object = YAML::dump(msg)

        q = @bunny.queue(queueName)
        q.bind(@direct_exchange)
        #q.publish( serialized_object )

        @direct_exchange.publish(serialized_object)
	end

# Gives an agent a mean to receive replies
#
# @param [String] queueName the name of the queue to monitor for messages
	def checkForReply( queueName )
        q = @bunny.queue(queueName)

        loop = true
        while loop do
            msg = q.pop[:payload]
            loop = ( msg == :queue_empty )
        end

		@msg = YAML::load(msg)
		return @msg.msg
	end
end

end