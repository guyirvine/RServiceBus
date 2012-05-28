require "amqp"


if ARGV.length == 1 then
	queueName = ARGV[0]
	index = 1
elsif ARGV.length == 2 then
	queueName = ARGV[0]
	index = ARGV[1].to_i
else
	abort( "Usage: PeekAtQueue <queue name> [index]" )
end


AMQP.start(:host => "localhost") do |connection|
	channel = AMQP::Channel.new(connection)
	queue   = channel.queue(queueName)

	finalPayload = nil
	1.upto(index) do |nbr|
		queue.pop( { :ack=>true } ) do |metadata, payload|
			puts nbr.to_s + ":" + index.to_s
			if nbr == index then
				puts payload
			end
		end	
	end
	
	puts finalPayload


    EventMachine.add_timer(0.5) do
      connection.close { EventMachine.stop }
    end # EventMachine.add_timer
end
