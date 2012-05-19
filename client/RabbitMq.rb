require "amqp"

AMQP.start(:host => "localhost") do |connection|
  channel = AMQP::Channel.new(connection)
  queue   = channel.queue("hello")

0.upto(9) do |request_nbr|
  puts "Sending request #{request_nbr}"
  channel.default_exchange.publish("HelloWorld", :routing_key => queue.name)
end


  EM.add_timer(0.5) do
    connection.close do
      EM.stop { exit }
    end
  end
end
