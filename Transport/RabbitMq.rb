require "amqp"


class Transport_RabbitMq

	def Listen( handlerList )
	
puts "Wait for Msgs"

AMQP.start(:host => "localhost") do |connection|
  channel = AMQP::Channel.new(connection)
  queue   = channel.queue("hello")

  Signal.trap("INT") do
    connection.close do
      EM.stop { exit }
    end
  end

  puts " [*] Waiting for messages. To exit press CTRL+C"

  queue.subscribe do |body|
	handler = handlerList[body]
    if handler == nil then
	    puts "Received request: [#{body}]"
    else
    	puts "Handler Found"
    	handler.Handle( body )
	end
  end
end


	end
end
