require "amqp"
require "yaml"


class HelloWorld
	attr_reader :name
	def initialize( name )
		@name = name
	end
end


AMQP.start(:host => "localhost") do |connection|
	channel = AMQP::Channel.new(connection)
	queue   = channel.queue("hello")

	0.upto(10) do |request_nbr|
		puts "Sending request #{request_nbr}"
		hello = HelloWorld.new( "Hello World! " + request_nbr.to_s )
		serialized_object = YAML::dump(hello)
		channel.default_exchange.publish(serialized_object, :routing_key => queue.name)
	end


	EM.add_timer(0.5) do
		connection.close do
			EM.stop { exit }
		end
	end
end

