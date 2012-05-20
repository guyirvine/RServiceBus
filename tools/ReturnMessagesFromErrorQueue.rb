require "amqp"


queueName = "hello"
errorQueueName = "error"
AMQP.start(:host => "localhost") do |connection|
	channel = AMQP::Channel.new(connection)
	queue   = channel.queue(queueName)
	errorQueue   = channel.queue( errorQueueName )

	Signal.trap("INT") do
		connection.close do
			EM.stop { exit }
		end
	end


	errorQueue.subscribe do |body|
		puts body
		channel.default_exchange.publish(body, :routing_key => queueName)
	end
	
end

