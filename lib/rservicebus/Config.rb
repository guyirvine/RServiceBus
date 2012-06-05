module RServiceBus

class Config
#host:
##	@appName: CreateUser
##	errorQueueName: error
#
#logger:
##	level: INFO
##	stdout: false
##	fileName: false
##	fileFormat: "[%l] %d :: %m"

	attr_reader :appName, :handlerPathList
	@config
	@appName
	
	@handlerPathList
	
	def initialize()
		abort( "You cannot call this class directly. Recommended subclass: ConfigFromFile" )
	end

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

	def loadHandlerPathList(host)
		path = self.getValue( "host", "messageHandlerPath", "MessageHandler" )

		@handlerPathList = Array.new
		path.split( "," ).each do |path|
			path = path.strip.chomp( "/" )
			@handlerPathList << path
		end

		host.handlerPathList = @handlerPathList
	end


	def loadHostSection( host )
		@appName = self.getValue( "host", "appName", "RServiceBus" )
		host.appName = @appName
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
