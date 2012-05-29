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

	attr_reader :returnAddress, :msgId

	def initialize( msg, returnAddress )
		@_msg=YAML::dump(msg)
		@returnAddress=returnAddress
		
		@msgId=UUIDTools::UUID.random_create
		@errorList = Array.new
	end

	def addErrorMsg( sourceQueue, errorString )
		@errorList << RServiceBus::ErrorMessage.new( sourceQueue, errorString )
	end

	def getLastErrorMsg
		return @errorList.last
	end

	def msg
		return YAML::load( @_msg )
	end

end


class Config
#host:
##	appName: CreateUser
##	errorQueueName: error
#
#logger:
##	level: INFO
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

	def loadMessageEndpointMappings( host )
		messageEndpointMappings=Hash.new

		if @config.has_key?( "MessageEndpointMappings" ) then
			@config["MessageEndpointMappings"].each{ |k,v| messageEndpointMappings[k] = v }
		end

		host.messageEndpointMappings=messageEndpointMappings
	end

	def getLoggingLevel
	# DEBUG < INFO < WARN < ERROR < FATAL
		loggingLevel = self.getValue( "logger", "level", "INFO" ).upcase
		case loggingLevel
			when "DEBUG"
				return Log4r::DEBUG
			when "INFO"
				return Log4r::INFO
			when "WARN"
				return Log4r::WARN
			when "ERROR"
				return Log4r::ERROR
			when "FATAL"
				return Log4r::FATAL
			else
				puts "Logging level, " + loggingLevel + " specified in config file, " + @configFilePath + " unknown."
				puts "**** Check file " + @configFilePath + ". Check in section 'logger', for the property 'level'. Current value is, " + loggingLevel + ", must be one of: DEBUG, INFO, WARN, ERROR, FATAL"
				abort()
		end
		
	end


	def loadConfig( host, configFilePath )
		configFilePath = configFilePath.nil? ? "RServiceBus.yml" : configFilePath
		@configFilePath = configFilePath
		if !File.exists?(configFilePath) then
			puts "Config file could not be found at: " + configFilePath
			puts "(You can specifiy a config file with: ruby RServiceBus [your config file path]"
			abort()
		end

		@config = YAML.load_file(configFilePath)

		appName = self.getValue( "host", "appName", "RServiceBus" )
		host.appName = appName
		host.localQueueName = appName
		host.errorQueueName = self.getValue( "host", "errorQueueName", "error" )
		host.maxRetries = self.getValue( "host", "maxRetries", 5 )
		host.forwardReceivedMessagesTo = self.getValue( "host", "forwardReceivedMessagesTo", nil )

		logger = Logger.new "rservicebus." + appName
		loggingLevel = self.getLoggingLevel()

		if self.getValue( "logger", "stdout", true ) != false then
			Outputter.stdout.level = loggingLevel
			logger.outputters = Outputter.stdout
		end

		fileName = self.getValue( "logger", "fileName", appName + ".log" );
		if fileName != false then
			file = FileOutputter.new(appName + ".file", :filename => fileName,:trunc => false)
			file.level = loggingLevel
			file.formatter = PatternFormatter.new(:pattern => self.getValue( "logger", "fileFormat", "[%l] %d :: %m" ))
			logger.add( file )
		end
		host.logger = logger


		self.loadMessageEndpointMappings( host )

	end
end

class HandlerLoader

	attr_reader :messageName, :handler

	@host

	@logger
	@filepath

	@requirePath
	@handlerName

	@messageName
	@handler

	def initialize( logger, filePath, host )
		@host = host

		@logger = logger
		@filePath = filePath
	end

	def parseFilepath
		@requirePath = "./" + @filePath.sub( ".rb", "")
		fileName = @filePath.sub( "MessageHandler/", "")
		@messageName = fileName.sub( ".rb", "" )
		@handlerName = "MessageHandler_" + @messageName

		@logger.debug @handlerName
		@logger.debug @filePath + ":" + fileName + ":" + @messageName + ":" + @handlerName
	end

	def loadHandlerFromFile
		require @requirePath
		begin
			@handler = Object.const_get(@handlerName).new();
		rescue Exception => e
			@logger.fatal "Expected class name: " + @handlerName + ", not found after require: " +  @requirePath
			@logger.fatal "**** Check in " + @filePath + " that the class is named : " + @handlerName
			@logger.fatal "( In case its not that )"
			raise e
		end
	end
	
	def setBusAttributeIfRequested
		if defined?( @handler.Bus ) then
			@handler.Bus = @host
			@logger.debug "Bus attribute set for: " + @handlerName
		end
	end

	def loadHandler()
		begin
			self.parseFilepath
			self.loadHandlerFromFile
			self.setBusAttributeIfRequested
			@logger.info "Loaded Handler: " + @handlerName
		rescue Exception => e
			@logger.fatal "Exception loading handler from file: " + @filePath
			@logger.fatal e.message
			@logger.fatal e.backtrace[0]

			abort()
		end

	end

end


class Host

	attr_reader :logger
	attr_writer :handlerList, :errorQueueName, :maxRetries, :localQueueName, :appName, :logger, :forwardReceivedMessagesTo, :messageEndpointMappings

	@appName

	@handlerList

	@errorQueueName
	@maxRetries

	@localQueueName
	
	@forwardReceivedMessagesTo
	@forwardReceivedMessagesToQueue
	
	@messageEndpointMappings
	
	# DEBUG < INFO < WARN < ERROR < FATAL
	@logger


	def initialize(configFilePath=nil)
		@forwardReceivedMessagesToQueue = nil
		RServiceBus::Config.new().loadConfig( self, configFilePath )
		@logger.info "MessageEndpointMappings: " + @messageEndpointMappings.to_s
	end


	def loadHandlers
		@logger.info "Load Message Handlers"


		@handlerList = {};
		Dir["MessageHandler/*.rb"].each do |filePath|
			handlerLoader = HandlerLoader.new( @logger, filePath, self )
			handlerLoader.loadHandler
			@handlerList[handlerLoader.messageName] = handlerLoader.handler;
		end

		return self
	end

	def run
		@logger.info "Starting the Host"

		AMQP.start(:host => "localhost") do |connection|
			@channel = AMQP::Channel.new(connection)
			@queue   = @channel.queue(@localQueueName)
			@errorQueue   = @channel.queue( @errorQueueName )
			if !@forwardReceivedMessagesTo.nil? then
				@logger.info "Forwarding all received messages to: " + @forwardReceivedMessagesTo.to_s
				@forwardReceivedMessagesToQueue = @channel.queue( @forwardReceivedMessagesTo )
			end

			Signal.trap("INT") do
				connection.close do
					EM.stop { exit }
				end
			end

			self.StartListeningToEndpoints
		end
	end


	def StartListeningToEndpoints
		@logger.info "Waiting for messages. To exit press CTRL+C"

		@queue.subscribe do |body|
			retries = @maxRetries
			begin
				@msg = YAML::load(body)
				self.HandleMessage()
				if !@forwardReceivedMessagesTo.nil? then
					@channel.default_exchange.publish(body, :routing_key => @forwardReceivedMessagesTo)
				end
	    	rescue Exception => e
		    	retry if (retries -= 1) > 0

				errorString = e.message + ". " + e.backtrace[0]
				@logger.error errorString

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
			@logger.warn "No handler found for: " + msgName
			raise "No Handler Found"
	    else
			@logger.debug "Handler found for: " + msgName
			begin
	   			handler.Handle( @msg.msg )
	   		rescue Exception => e
				@logger.error "An error occured in Handler: " + handler.class.name
				raise e
	   		end
    	end
	end

	def Reply( string )
		@logger.debug "Reply: " + string + " To: " + @msg.returnAddress

		msg = RServiceBus::Message.new( string, @localQueueName )
		serialized_object = YAML::dump(msg)

		queue = @channel.queue(@msg.returnAddress)
		@channel.default_exchange.publish(serialized_object, :routing_key => @msg.returnAddress)
	end


	def Send( msg )
		@logger.debug "Bus.Send"


		msgName = msg.class.name
		if !@messageEndpointMappings.has_key?( msgName ) then
			@logger.warn "No end point mapping found for: " + msgName
			@logger.warn "**** Check in RServiceBus.yml that the section MessageEndpointMappings contains an entry named : " + msgName
			raise "No end point mapping found for: " + msgName
		end
		rMsg = RServiceBus::Message.new( msg, "herdservice" )
		serialized_object = YAML::dump(rMsg)

		queueName = @messageEndpointMappings[msgName]
		queue = @channel.queue(queueName)

		@logger.debug "Sending: " + msgName + " to: " + queueName
		@channel.default_exchange.publish(serialized_object, :routing_key => queueName)
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
