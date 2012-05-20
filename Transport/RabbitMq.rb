require "amqp"


class Transport_RabbitMq


	def initialize( handlerList, errorQueueName )
		@handlerList = handlerList
		@errorQueueName = errorQueueName
	end

	def Run()
	
		puts "Wait for Msgs"

		AMQP.start(:host => "localhost") do |connection|
			@channel = AMQP::Channel.new(connection)
			@queue   = @channel.queue("hello")
			@errorQueue   = @channel.queue( @errorQueueName )

			Signal.trap("INT") do
				connection.close do
					EM.stop { exit }
				end
			end

			self.StartListeningToEndpoints
		end
		
	end
	
	def StartListeningToEndpoints
		puts " [*] Waiting for messages. To exit press CTRL+C"

		@queue.subscribe do |body|
			begin
				self.HandleMessage( body )
	    	rescue
				@channel.default_exchange.publish(body, :routing_key => @errorQueueName)
    		end
		end
	end

	def HandleMessage(body)
		handler = @handlerList[body]
		if handler == nil then
			puts "Received request: [#{body}]"
			@channel.default_exchange.publish(body, :routing_key => @errorQueueName)
	    else
			puts "Handler Found"
   			handler.Handle( body )
    	end
	end
end

