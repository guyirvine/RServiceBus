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
    
    def process
		#Get the next job from the source queue
        job = @source.reserve @timeout
        msg = YAML::load(job.body)

        log "job: #{job.body}", true
        
        
		#Get destination url from job
        remote_host = msg.remoteHostName
        remote_user = getValue( "REMOTE_USER_#{remote_host.upcase}", "beanstalk" )
        gateway = Net::SSH::Gateway.new(remote_host, remote_user)
        
        # Open port 27018 to forward to 127.0.0.11300 on the remote host
        gateway.open('127.0.0.1', 11300, 27018)

		log "Connect to destination beanstalk"
        begin
            destinationUrl = '127.0.0.1:27018'
            destination = Beanstalk::Pool.new([destinationUrl])
            rescue Exception => e
            if e.message == "Beanstalk::NotConnected" then
                puts "***Could not connect to destination, check beanstalk is running at, #{destinationUrl}"
                raise CouldNotConnectToDestination.new
            end
            raise
        end

        log "Put msg, #{job.body}", true
        destination.use( msg.remoteQueueName )
        destination.put( job.body )
 
        if !ENV['AUDIT_QUEUE_NAME'].nil? then
            @source.use ENV['AUDIT_QUEUE_NAME']
            @source.put job.body
        end
		#removeJob
		job.delete
        
        
        gateway.shutdown!
		log "Job sent to, #{remote_user}@#{remote_host}/#{msg.remoteQueueName}"
        
        rescue Exception => e
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
	end
end


end

