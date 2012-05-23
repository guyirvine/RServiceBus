
class RServiceBusConfig
	def loadConfig( host )
		host.appName = "CreateUser"
	
		host.errorQueueName = "error"
		host.localQueueName = "userservice"
		host.incomingQueueName = "user"

		host.logger = Logger.new "rservicebus." + host.appName
		Outputter.stdout.level = Log4r::INFO
		host.logger.outputters = Outputter.stdout

		file = FileOutputter.new(host.appName + ".file", :filename => host.appName + ".log",:trunc => false)
		file.formatter = PatternFormatter.new(:pattern => "[%l] %d :: %m")
		host.logger.add( file )


	end
end

