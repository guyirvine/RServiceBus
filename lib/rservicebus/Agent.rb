module RServiceBus
require 'beanstalk-client'

class Agent
	@beanstalk
	
	def initialize(url=['localhost:11300'])
		@beanstalk = Beanstalk::Pool.new(url)
	end

	def sendMsg(messageObj, queueName, returnAddress=nil)
		msg = RServiceBus::Message.new( messageObj, returnAddress )
		serialized_object = YAML::dump(msg)

		@beanstalk.use( queueName )
		@beanstalk.put( serialized_object )
	end

end

end