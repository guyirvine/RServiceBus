module RServiceBus

class Config
#host:
##	@appName: CreateUser
##	errorQueueName: error
#

	attr_reader :appName, :handlerPathList
	@config
	@appName
	
	@handlerPathList
	
	def getValue( name, default=nil )
		if ENV[name].nil? then
			return default
		end
		
		return ENV[name]
	end

	def loadMessageEndpointMappings( host )
		mapping = self.getValue( "RSERVICEBUS_MESSAGEENDPOINTMAPPINGS" )

		messageEndpointMappings=Hash.new
		if !mapping.nil? then
			mapping.split( ";" ).each do |line|
				match = line.match( /(.+):(.+)/ )
				messageEndpointMappings[match[0]] = match[1]
			end
		end

		host.messageEndpointMappings=messageEndpointMappings
	end

	def loadHandlerPathList(host)
		path = self.getValue( "RSERVICEBUS_MESSAGEHANDLERPATH", "MessageHandler" )

		@handlerPathList = Array.new
		path.split( ";" ).each do |path|
			path = path.strip.chomp( "/" )
			@handlerPathList << path
		end

		host.handlerPathList = @handlerPathList
	end


	def loadHostSection( host )
		path = self.getValue( "RSERVICEBUS_APPNAME", "RServiceBus" )
		localQueueName = self.getValue( "RSERVICEBUS_APPNAME", "RServiceBus" )
#		@appName = self.getValue( "host", "appName", "RServiceBus" )
#		host.appName = @appName
		host.localQueueName = @appName
		host.errorQueueName = self.getValue( "host", "errorQueueName", "error" )
		host.maxRetries = self.getValue( "host", "maxRetries", 5 )
		host.forwardReceivedMessagesTo = self.getValue( "host", "forwardReceivedMessagesTo", nil )

		self.loadHandlerPathList(host)
	end


	def configureLogging( host )
		logger = Logger.new "rservicebus." + @appName
		loggingLevel = self.getLoggingLevel()

		if self.getValue( "logger", "stdout", true ) != false then
			Outputter.stdout.level = loggingLevel
			logger.outputters = Outputter.stdout
		end

		fileName = self.getValue( "logger", "fileName", @appName + ".log" );
		if fileName != false then
			file = FileOutputter.new(@appName + ".file", :filename => fileName,:trunc => false)
			file.level = loggingLevel
			file.formatter = PatternFormatter.new(:pattern => self.getValue( "logger", "fileFormat", "[%l] %d :: %m" ))
			logger.add( file )
		end
		host.logger = logger
	end

	def processConfig( host )
		self.loadHostSection(host)
		self.configureLogging(host)
		self.loadMessageEndpointMappings( host )


		return self
	end

end


class ConfigFromFile<Config

	def getConfigurationFilePath(configFilePath)
		configFilePath = configFilePath.nil? ? "RServiceBus.yml" : configFilePath
		if File.exists?(configFilePath) == false then
			puts "Config file could not be found at: " + configFilePath
			puts "(You can specifiy a config file with: ruby RServiceBus [your config file path]"
			abort()
		end

		return configFilePath
	end


	def initialize(configFilePath )
		configFilePath = self.getConfigurationFilePath(configFilePath)
		@config = YAML.load_file(configFilePath)
	end

end

class ConfigFromYAMLObject<Config

	def initialize(config )
		@config = config
	end

end


end
