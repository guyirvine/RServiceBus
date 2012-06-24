module RServiceBus

#Collects and reports configuration information for an rservicebus host
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

	def getValue( name, default=nil )
		value = ENV["#{name}"].nil? ? default : ENV["#{name}"];
		puts "Env value: #{name}: #{value}"
		return value
	end

	def loadMessageEndpointMappings()
		mapping = self.getValue( "MESSAGE_ENDPOINT_MAPPINGS" )

		messageEndpointMappings=Hash.new
		if !mapping.nil? then
			mapping.split( ";" ).each do |line|
				match = line.match( /(.+):(.+)/ )
				messageEndpointMappings[match[1]] = match[2]
			end
		end

		@messageEndpointMappings=messageEndpointMappings

		return self
	end

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
		@localQueueName = @appName
		@errorQueueName = self.getValue( "ERROR_QUEUE_NAME", "error" )
		@maxRetries = self.getValue( "MAX_RETRIES", "5" ).to_i
		@forwardReceivedMessagesTo = self.getValue( "FORWARD_RECEIVED_MESSAGES_TO" )

		return self
	end

	def loadContracts()
		if self.getValue( "CONTRACTS", "./Contract" ).nil? then
			return self
		end

		self.getValue( "CONTRACTS", "./Contract" ).split( ";" ).each do |path|
			puts "Loading contracts from, #{path}"
			require path
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
