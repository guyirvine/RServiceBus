require "amqp"
require "yaml"


require "../MessageTypes"


class Agent_RabbitMq


	def send(messageObj, queueName, returnAddress )
		AMQP.start(:host => "localhost") do |connection|
			channel = AMQP::Channel.new(connection)

			msg = RServiceBus_Message.new( messageObj, returnAddress )
			serialized_object = YAML::dump(msg)

			queue = channel.queue(queueName)

			channel.default_exchange.publish(serialized_object, :routing_key => queueName)

			EM.add_timer(0.5) do
				connection.close do
					EM.stop { exit }
				end
			end
		end
	end

end
