require "amqp"
require "yaml"

require "../RServiceBus"


class HelloWorld
	attr_reader :name
	def initialize( name )
		@name = name
	end
end


errorQueueName = "error"
AMQP.start(:host => "localhost") do |connection|
	channel = AMQP::Channel.new(connection)
	errorQueue   = channel.queue( errorQueueName )

	Signal.trap("INT") do
		connection.close do
			EM.stop { exit }
		end
	end

	errorQueue.status do |number_of_messages, number_of_consumers|
		puts
		puts "Attempting to return #{number_of_messages} to their source queue"
		puts


		1.upto(number_of_messages) do |request_nbr|
    	    errorQueue.pop( { :ack=>true } ) do |metadata, payload|
    	    	puts "#" + request_nbr.to_s + ": " + payload
				msg = YAML::load(payload)
				queueName = msg.errorMsg.sourceQueue
		
		
				channel.default_exchange.publish(msg, :routing_key => queueName)
				metadata.ack
        	end
		end
	end

	
    EventMachine.add_timer(0.5) do
      connection.close { EventMachine.stop }
    end # EventMachine.add_timer

end
