require 'beanstalk-client'
require 'rservicebus'
require 'net/ssh/gateway'

module RServiceBus

class CouldNotConnectToDestination<StandardError
end


#ToDo: Poison Message? Can I bury with timeout in beanstalk ?
#Needs to end up on an error queue, destination queue may be down.


class Transporter
    
	def log( string, verbose=false )
        if verbose == false ||
            ( !ENV["VERBOSE"].nil? && ENV["VERBOSE"].upcase == "TRUE") then
            puts string
        end
	end
    
    def getValue( name, default=nil )
        value = ( ENV[name].nil?  || ENV[name] == ""  ) ? default : ENV[name];
        log "Env value: #{name}: #{value}"
        return value
    end
    
	def connectToSourceBeanstalk
		sourceQueueName = getValue( 'SOURCE_QUEUE_NAME', "transport-out" )
		sourceUrl = getValue( 'SOURCE_URL', "127.0.0.1:11300" )
		@source = Beanstalk::Pool.new([sourceUrl])
        @source.watch sourceQueueName
        
		log "Connected to, #{sourceQueueName}@#{sourceUrl}"
        
        rescue Exception => e
        puts "Error connecting to Beanstalk"
        puts "Host string, #{sourceUrl}"
        if e.message == "Beanstalk::NotConnected" then
            puts "***Most likely, beanstalk is not running. Start beanstalk, and try running this again."
            puts "***If you still get this error, check beanstalk is running at, #{sourceUrl}"
            else
            puts e.message
            puts e.backtrace
        end
		abort();
	end
    
    def connectToRemoteSSH( remoteHostName )
        return if @remoteHostName == remoteHostName
        
        self.disconnectFromRemoteSSH

		#Get destination url from job
        @remoteHostName = remoteHostName
        @remoteUserName = getValue( "REMOTE_USER_#{remoteHostName.upcase}", "beanstalk" )
        @gateway = Net::SSH::Gateway.new(remoteHostName, @remoteUserName)
        
        # Open port 27018 to forward to 127.0.0.11300 on the remote host
        @gateway.open('127.0.0.1', 11300, 27018)
        log "Connect to Remote SSH, #{@remoteHostName}"
        
        return @gateway
    end

    def disconnectFromRemoteSSH
        return if @gateway.nil?
        
        log "Disconnect from Remote SSH, #{@remoteHostName}"
        @gateway.shutdown!
        @remoteHostName = nil
        @gateway = nil
    end

    
    def connectToRemoteBeanstalk( remoteHostName, remoteQueueName )
        self.connectToRemoteSSH( remoteHostName )
        
        #Test connection
        return if @remoteQueueName == remoteQueueName
        

        log "Connect to Remote Beanstalk, #{remoteQueueName}"
        begin
            destinationUrl = '127.0.0.1:27018'
            @destination = Beanstalk::Pool.new([destinationUrl])
            rescue Exception => e
            if e.message == "Beanstalk::NotConnected" then
                puts "***Could not connect to destination, check beanstalk is running at, #{destinationUrl}"
                raise CouldNotConnectToDestination.new
            end
            raise
        end
        
        log "Use queue, #{remoteQueueName}", true
        @destination.use( remoteQueueName )
        @remoteQueueName = remoteQueueName
    end
    
    def disconnectFromRemoteBeanstalk
        self.disconnectFromRemoteSSH
        return if @destination.nil?

        log "Disconnect from Remote Beanstalk, #{@remoteQueueName}"
        @destination.close
        @remoteQueueName = nil
    end

    
    def process
		#Get the next job from the source queue
        job = @source.reserve @timeout
        msg = YAML::load(job.body)

        #        log "job: #{job.body}", true

        self.connectToRemoteBeanstalk( msg.remoteHostName, msg.remoteQueueName )

        log "Put msg", true
        @destination.put( job.body )
 
        if !ENV['AUDIT_QUEUE_NAME'].nil? then
            @source.use ENV['AUDIT_QUEUE_NAME']
            @source.put job.body
        end
		#removeJob
		job.delete
        
		log "Job sent to, #{@remoteUserName}@#{@remoteHostName}/#{@remoteQueueName}"


        rescue Exception => e
        self.disconnectFromRemoteSSH
        if e.message == "TIMED_OUT" then
            log "No Msg", true
            return
        end
        raise e
    end
    
	def Run
		@timeout = getValue( 'TIMEOUT', 5 )
		connectToSourceBeanstalk
		while true
			process
		end
        self.disconnectFromRemoteSSH
	end
end


end

