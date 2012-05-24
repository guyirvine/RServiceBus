require "rubygems"
require "amqp"
require "yaml"
require "uuidtools"
require "log4r"


include Log4r


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

	def addErrorMsg( sourceQueue, errorString )
		@errorMsg = RServiceBus::ErrorMessage.new( sourceQueue, errorString )
	end

	def msg
		return YAML::load( @_msg )
	end

end


class Config
#host:
##	appName: CreateUser
##	errorQueueName: error
#	localQueueName: userservice
#	incomingQueueName: user
#
#logger:
##	level: Log4r::INFO
##	stdout: false
##	fileName: false
##	fileFormat: "[%l] %d :: %m"


	@config

	def getValue( section, name, default )
		if @config.has_key?(section) then
			if @config[section].nil? then
				return default
			end
			return @config[section].has_key?(name) ? @config[section][name] : default
		end
		return default
	end

	def loadConfig( host, configFilePath )
		configFilePath = configFilePath.nil? ? "RServiceBus.yml" : configFilePath
		if !File.exists?(configFilePath) then
			puts "Config file could not be found at: " + configFilePath
			puts "(You can specifiy a config file with: ruby RServiceBus [your config file path]"
			abort()
		end

		@config = YAML.load_file(configFilePath)

		host.appName = self.getValue( "host", "appName", "CreateUser" )
		host.errorQueueName = self.getValue( "host", "errorQueueName", "error" )
		host.localQueueName = self.getValue( "host", "localQueueName", "local" )
		host.incomingQueueName = self.getValue( "host", "incomingQueueName", "incoming" )

		host.logger = Logger.new "rservicebus." + host.appName
		loggingLevel = self.getValue( "logger", "level", Log4r::INFO )

		if self.getValue( "logger", "stdout", true ) != false then
			Outputter.stdout.level = loggingLevel
			host.logger.outputters = Outputter.stdout
		end

		fileName = self.getValue( "logger", "fileName", host.appName + ".log" );
		if fileName != false then
			file = FileOutputter.new(host.appName + ".file", :filename => fileName,:trunc => false)
			file.level = loggingLevel
			file.formatter = PatternFormatter.new(:pattern => self.getValue( "logger", "fileFormat", "[%l] %d :: %m" ))
			host.logger.add( file )
		end


	end
end


class Host

	attr_writer :handlerList, :errorQueueName, :localQueueName, :incomingQueueName, :appName, :logger
	attr_reader :appName, :logger

	@appName

	@handlerList

	@errorQueueName
	@localQueueName
	@incomingQueueName
	
	# DEBUG < INFO < WARN < ERROR < FATAL
	@logger


	def initialize(configFilePath=nil)
		RServiceBus::Config.new().loadConfig( self, configFilePath )
	end


	def loadHandlers
		self.logger.info "Load Message Handlers"


		@handlerList = {};
		Dir["MessageHandler/*.rb"].each do |filePath|
			begin
				requirePath = "./" + filePath.sub( ".rb", "")
				fileName = filePath.sub( "MessageHandler/", "")
				messageName = fileName.sub( ".rb", "" )
				handlerName = "MessageHandler_" + messageName
				self.logger.debug handlerName
				self.logger.debug filePath + ":" + fileName + ":" + messageName + ":" + handlerName


				require requirePath
				begin
					handler = Object.const_get(handlerName).new();
				rescue Exception => e
					self.logger.fatal "Expected class name: " + handlerName + ", not found in file: " +  filePath
					self.logger.fatal "**** Check in " + filePath + " that the class is named : " + handlerName
					self.logger.fatal "( In case its not that )"
					raise
				end
				if defined?( handler.Bus ) then
					self.logger.debug "Setting Bus attribute for: " + handlerName
					handler.Bus = self
				end if
				@handlerList[messageName] = handler;

				self.logger.info "Loaded Handler: " + handlerName + " for: " + messageName
			rescue Exception => e
				self.logger.fatal "Exception loading handler from file: " + filePath
				self.logger.fatal e.message
				self.logger.fatal e.backtrace[0]

				abort()
			end
		end

		return self
	end

	def run
		self.logger.info "Starting the Host"

		AMQP.start(:host => "localhost") do |connection|
			@channel = AMQP::Channel.new(connection)
			@queue   = @channel.queue(@incomingQueueName)
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
		self.logger.info "Waiting for messages. To exit press CTRL+C"

		@queue.subscribe do |body|
			begin
				@msg = YAML::load(body)
				self.HandleMessage()
	    	rescue Exception => e
				errorString = e.message + ". " + e.backtrace[0]
				self.logger.error errorString

				@msg.addErrorMsg( @queue.name, errorString )
				serialized_object = YAML::dump(@msg)
				@channel.default_exchange.publish(serialized_object, :routing_key => @errorQueueName)
    		end
		end
	end

	def HandleMessage()
		msgName = @msg.msg.class.name
		handler = @handlerList[msgName]

		if handler == nil then
			self.logger.warn "No handler found for: " + msgName
			raise "No Handler Found"
	    else
			self.logger.debug "Handler found for: " + msgName
   			handler.Handle( @msg.msg )
    	end
	end

	def Reply( string )
		self.logger.debug "Reply: " + string + " To: " + @msg.returnAddress


		msg = RServiceBus::Message.new( string, @localQueueName )
		serialized_object = YAML::dump(msg)


		queue = @channel.queue(@msg.returnAddress)
		@channel.default_exchange.publish(serialized_object, :routing_key => @msg.returnAddress)
	end


end


end


if __FILE__ == $0
	if ARGV.length > 1 then
        abort( "Usage: RServiceBus [config file name]" )
	end
	configFilePath = ARGV.length == 0 ? nil : ARGV[0]

	RServiceBus::Host.new(configFilePath)
		.loadHandlers()
		.run()
end
