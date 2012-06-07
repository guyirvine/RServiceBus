module RServiceBus
require 'beanstalk-client'

class Agent
	@beanstalk
	
	def initialize()
		@beanstalk = Beanstalk::Pool.new(['localhost:11300'])
	end

	def sendMsg(messageObj, queueName, returnAddress)
		msg = RServiceBus::Message.new( messageObj, returnAddress )
		serialized_object = YAML::dump(msg)

		@beanstalk.use( queueName )
		@beanstalk.put( serialized_object )
	end

end

end