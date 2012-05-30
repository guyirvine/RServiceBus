require "amqp"


if ARGV.length != 1 then
	abort( "Usage: DeleteQueueByName <queue name>" )
end
queueName = ARGV[0]

AMQP.start(:host => "localhost") do |connection|
	channel = AMQP::Channel.new(connection)
        queue   = channel.queue(queueName)
	queue.delete(queueName)

	EventMachine.add_timer(0.5) do
		connection.close { EventMachine.stop }
	end # EventMachine.add_timer
    	
end

