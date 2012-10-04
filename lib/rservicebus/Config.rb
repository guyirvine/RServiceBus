module RServiceBus

#Marshals configuration information for an rservicebus host
class Config
	attr_reader :appName, :messageEndpointMappings, :handlerPathList, :localQueueName, :errorQueueName, :maxRetries, :forwardReceivedMessagesTo, :verbose, :beanstalkHost, :queueTimeout, :statOutputCountdown, :contractList, :libList, :auditQueueName

	@appName
	@messageEndpointMappings
	@handlerPathList
	@contractList

	@localQueueName
	@errorQueueName
	@auditQueueName
	@maxRetries
	@forwardReceivedMessagesTo

	@verbose
	
	@beanstalkHost

	@queueTimeout

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
		@handlerPathList = Array.new
		path.split( ";" ).each do |path|
			path = path.strip.chomp( "/" )
			@handlerPathList << path
		end

		return self
	end

	def loadHostSection()
		@appName = self.getValue( "APPNAME", "RServiceBus" )
		@localQueueName = self.getValue( "LOCAL_QUEUE_NAME", @appName )
		@errorQueueName = self.getValue( "ERROR_QUEUE_NAME", "error" )
        @auditQueueName = self.getValue( "AUDIT_QUEUE_NAME" )
		@maxRetries = self.getValue( "MAX_RETRIES", "5" ).to_i
		@forwardReceivedMessagesTo = self.getValue( "FORWARD_RECEIVED_MESSAGES_TO" )
		@queueTimeout = self.getValue( "QUEUE_TIMEOUT", "5" ).to_i
		@statOutputCountdown = self.getValue( "STAT_OUTPUT_COUNTDOWN", "100" ).to_i

		return self
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

#Marshals paths for contracts
#
#Note. .rb extension is optional
#
#Expected format;
#	/one/two/Contracts
	def loadContracts()
		if self.getValue( "CONTRACTS", "./Contract" ).nil? then
			return self
		end
        @contractList = Array.new

		self.getValue( "CONTRACTS", "./Contract" ).split( ";" ).each do |path|
			log "Loading contracts from, #{path}"
			self.ensureContractFileExists( path )
			@contractList << path
		end
		return self
	end

    #Marshals paths for lib
    #
    #Note. .rb extension is optional
    #
    #Expected format;
    #	/one/two/Contracts
	def loadLibs()
        @libList = Array.new

        path = self.getValue( "LIB" )
        path = "./lib" if path.nil? and File.exists?( "./lib" )
		if path.nil? then
			return self
		end

		path.split( ";" ).each do |path|
			log "Loading libs from, #{path}"
			if !File.exists?( path ) then
                puts "Error while processing libs"
                puts "*** path, #{path}, should point to a ruby file, with extention .rb, or"
                puts "*** path, #{path}, should point to a directory than conatins ruby files, that have extention .rb"
                abort()
                end
			@libList << path
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

    #Marshals paths for working_dirs
    #
    #Note. trailing slashs will be stripped
    #
    #Expected format;
    #	<path 1>;<path 2>
	def loadWorkingDirList()
		pathList = self.getValue( "WORKING_DIR" )
        return self if pathList.nil?

		pathList.split( ";" ).each do |path|
            
			path = path.strip.chomp( "/" )
            if Dir.exists?( "#{path}/MessageHandler" ) then
                @handlerPathList << "#{path}/MessageHandler"
            end

            if File.exists?( "#{path}/Contract.rb" ) then
                @contractList << "#{path}/Contract.rb"
            end

            if File.exists?( "#{path}/lib" ) then
                @libList << "#{path}/lib"
            end
		end

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
