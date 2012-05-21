require "amqp"
require "yaml"
require "./MessageTypes/ErrorMessage"


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
	    	rescue Exception => e
	    		errorMsg = e.message + ". " + e.backtrace[0]
	    		puts errorMsg

	    		errorObj = ErrorMessage.new( body, @queue.name, errorMsg )
				serialized_object = YAML::dump(errorObj)
				@channel.default_exchange.publish(serialized_object, :routing_key => @errorQueueName)
    		end
		end
	end

	def HandleMessage(body)
		msg = YAML::load(body)
		msgName = msg.class.name
		handler = @handlerList[msgName]
		if handler == nil then
			puts "Received request: [#{body}]"
			@channel.default_exchange.publish(body, :routing_key => @errorQueueName)
	    else
			puts "Handler Found"
   			handler.Handle( msg )
    	end
	end
end
