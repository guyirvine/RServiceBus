require "amqp"
require "yaml"
require "./MessageTypes"


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
				msg = YAML::load(body)
				self.HandleMessage( msg )
	    	rescue Exception => e
				msg.addErrorMsg( @queue.name, e )
				serialized_object = YAML::dump(msg)
				@channel.default_exchange.publish(serialized_object, :routing_key => @errorQueueName)
    		end
		end
	end

	def HandleMessage(msg)
		msgName = msg.msg.class.name
		handler = @handlerList[msgName]
		if handler == nil then
			raise "No Handler Found"
	    else
			puts "Handler Found"
   			handler.Handle( msg.msg )
    	end
	end

end
