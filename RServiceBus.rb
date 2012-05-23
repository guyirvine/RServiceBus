require "rubygems"
require "amqp"
require "yaml"
require "uuidtools"


module RServiceBus


class Agent


	def _sendMsg(channel, messageObj, queueName, returnAddress)
		msg = RServiceBus::Message.new( messageObj, returnAddress )
		serialized_object = YAML::dump(msg)

		queue = channel.queue(queueName)

		channel.default_exchange.publish(serialized_object, :routing_key => queueName)
	end


	def sendMsg(channel, messageObj, queueName, returnAddress)
		self._sendMsg(channel, messageObj, queueName, returnAddress)
	end


	def send(messageObj=nil, queueName=nil, returnAddress=nil )
		AMQP.start(:host => "localhost") do |connection|
			channel = AMQP::Channel.new(connection)


			self.sendMsg(channel, messageObj, queueName, returnAddress)


			EM.add_timer(0.5) do
				connection.close do
					EM.stop { exit }
				end
			end
		end
	end

end


class ErrorMessage

	attr_reader :sourceQueue, :errorMsg

	def initialize( sourceQueue, errorMsg )
		@sourceQueue=sourceQueue
		@errorMsg=errorMsg
	end

end


class Message

	attr_reader :returnAddress, :msgId, :errorMsg

	def initialize( msg, returnAddress )
		@_msg=YAML::dump(msg)
		@returnAddress=returnAddress
		
		@msgId=UUIDTools::UUID.random_create
		@errorMsg = nil
	end

	def addErrorMsg( sourceQueue, e )
		errorString = e.message + ". " + e.backtrace[0]
		puts errorString

		@errorMsg = RServiceBus::ErrorMessage.new( sourceQueue, errorString )
	end

	def msg
		return YAML::load( @_msg )
	end

end


class Host

	attr_writer :handlerList

	@handlerList
	@localQueue

	def initialize( errorQueueName )
		@errorQueueName = errorQueueName
		@localQueue = "localQ"
	end


	def loadHandlers
		puts "Load Message Handlers"


		@handlerList = {};
		Dir["MessageHandler/*.rb"].each do |filePath|
			requirePath = "./" + filePath.sub( ".rb", "")
			fileName = filePath.sub( "MessageHandler/", "")
			messageName = fileName.sub( ".rb", "" )
			handlerName = "MessageHandler_" + messageName
			puts filePath + ":" + fileName + ":" + messageName + ":" + handlerName


			require requirePath
			handler = Object.const_get(handlerName).new();
			if defined?( handler.Bus ) then
				puts "Writing"
				handler.Bus = self
			end if
			@handlerList[messageName] = handler;

			puts "Loaded Handler for: " + messageName
		end
		
		return self
	end

	def run
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
				@msg = YAML::load(body)
				self.HandleMessage()
	    	rescue Exception => e
				@msg.addErrorMsg( @queue.name, e )
				serialized_object = YAML::dump(@msg)
				@channel.default_exchange.publish(serialized_object, :routing_key => @errorQueueName)
    		end
		end
	end

	def HandleMessage()
		msgName = @msg.msg.class.name
		handler = @handlerList[msgName]

		if handler == nil then
			raise "No Handler Found"
	    else
			puts "Handler Found"
   			handler.Handle( @msg.msg )
    	end
	end

	def Reply( string )
		puts "Reply: " + string + " To: " + @msg.returnAddress


		msg = RServiceBus::Message.new( string, @localQueue )
		serialized_object = YAML::dump(msg)


		queue = @channel.queue(@msg.returnAddress)
		@channel.default_exchange.publish(serialized_object, :routing_key => @msg.returnAddress)
	end

end


end


if __FILE__ == $0
	RServiceBus::Host.new("error")
		.loadHandlers()
		.run()
end
