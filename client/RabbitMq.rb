require "../RServiceBus"


class HelloWorld
	attr_reader :name
	def initialize( name )
		@name = name
	end
end

class Agent<RServiceBus_Agent
	def sendMsg(channel, messageObj, queueName, returnAddress)
		0.upto(100) do |request_nbr|
			self._sendMsg(channel, HelloWorld.new( "Hello World! " + request_nbr.to_s ), "hello", "helloResponse" )
		end
	end

end

Agent.new().send()

