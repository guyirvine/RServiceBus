module RServiceBus

#Marshals configuration information for an rservicebus host
class Config
	attr_reader :appName, :messageEndpointMappings, :handlerPathList, :localQueueName, :errorQueueName, :maxRetries, :forwardReceivedMessagesTo, :verbose, :beanstalkHost

	@appName
	@messageEndpointMappings
	@handlerPathList

	@localQueueName
	@errorQueueName
	@maxRetries
	@forwardReceivedMessagesTo

	@verbose
	
	@beanstalkHost

	def initialize()
		puts "Cannot instantiate config directly."
		puts "For production, use ConfigFromEnv."
		puts "For debugging or testing, you could try ConfigFromSetter"
		abort()
	end

	def log( string )
		puts string
	end

	def getValue( name, default=nil )
		value = ( ENV[name].nil?  || ENV[name] == ""  ) ? default : ENV[name];
		log "Env value: #{name}: #{value}"
		return value
	end

#Marshals data for message end points
#
#Expected format;
#	<msg mame 1>:<end point 1>;<msg mame 2>:<end point 2>
	def loadMessageEndpointMappings()
		mapping = self.getValue( "MESSAGE_ENDPOINT_MAPPINGS" )

		messageEndpointMappings=Hash.new
		if !mapping.nil? then
			mapping.split( ";" ).each do |line|
				match = line.match( /(.+):(.+)/ )
				if match.nil? then
					log "Mapping string provided is invalid"
					log "The entire mapping string is: #{mapping}"
					log "*** Could not find ':' in mapping entry, #{line}"
					exit()
				end
				messageEndpointMappings[match[1]] = match[2]
			end
		end

		@messageEndpointMappings=messageEndpointMappings

		return self
	end

#Marshals paths for message handlers
#
#Note. trailing slashs will be stripped
#
#Expected format;
#	<path 1>;<path 2>
	def loadHandlerPathList()
		path = self.getValue( "MSGHANDLERPATH", "./MessageHandler" )
		handlerPathList = Array.new
		path.split( ";" ).each do |path|
			path = path.strip.chomp( "/" )
			handlerPathList << path
		end

		@handlerPathList = handlerPathList

		return self
	end

	def loadHostSection()
		@appName = self.getValue( "APPNAME", "RServiceBus" )
		@localQueueName = self.getValue( "LOCAL_QUEUE_NAME", @appName )
		@errorQueueName = self.getValue( "ERROR_QUEUE_NAME", "error" )
		@maxRetries = self.getValue( "MAX_RETRIES", "5" ).to_i
		@forwardReceivedMessagesTo = self.getValue( "FORWARD_RECEIVED_MESSAGES_TO" )

		return self
	end

	def performRequire( path )
		require path
	end

	def ensureContractFileExists( path )
		if !( File.exists?( path ) ||
				File.exists?( "#{path}.rb" ) ) then
			puts "Error while processing contracts"
			puts "*** path, #{path}, provided does not exist as a file"
			abort()
		end
		if !( File.extname( path ) == "" ||
				File.extname( path ) == ".rb" ) then
			puts "Error while processing contracts"
			puts "*** path, #{path}, should point to a ruby file, with extention .rb"
			abort()
		end
	end

	def loadContracts()
		if self.getValue( "CONTRACTS", "./Contract" ).nil? then
			return self
		end

		self.getValue( "CONTRACTS", "./Contract" ).split( ";" ).each do |path|
			log "Loading contracts from, #{path}"
			self.ensureContractFileExists( path )
			self.performRequire( path )
		end
		return self
	end

	def configureLogging()
		@verbose = !self.getValue( "VERBOSE", nil ).nil?

		return self
	end

	def configureBeanstalk
		@beanstalkHost = self.getValue( "BEANSTALK", "localhost:11300" )

		return self
	end


end


class ConfigFromEnv<Config

	def initialize()
	end

end

class ConfigFromSetter<Config
	attr_writer :appName, :messageEndpointMappings, :handlerPathList, :localQueueName, :errorQueueName, :maxRetries, :forwardReceivedMessagesTo, :verbose, :beanstalkHost

	def initialize()
	end

end


end
