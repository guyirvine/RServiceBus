module RServiceBus

class Agent


	def _sendMsg(channel, messageObj, queueName, returnAddress)
		msg = RServiceBus::Message.new( messageObj, returnAddress )
		serialized_object = YAML::dump(msg)

		queue = channel.queue(queueName)

		channel.default_exchange.publish(serialized_object, :routing_key => queueName)
	end

	def sendMsg(channel, messageObj, queueName, returnAddress)
		self._sendMsg(channel, messageObj, queueName, returnAddress)
	end


	def send(messageObj=nil, queueName=nil, returnAddress=nil )
		AMQP.start(:host => "localhost") do |connection|
			channel = AMQP::Channel.new(connection)


			self.sendMsg(channel, messageObj, queueName, returnAddress)


			EM.add_timer(0.5) do
				connection.close do
					EM.stop { exit }
				end
			end
		end
	end

end

end