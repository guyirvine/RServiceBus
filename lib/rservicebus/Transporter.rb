require 'beanstalk-client'
require 'rservicebus'
require 'net/ssh/gateway'

module RServiceBus
    
    class CouldNotConnectToDestination<StandardError
    end
    
    
    #ToDo: Poison Message? Can I bury with timeout in beanstalk ?
    #Needs to end up on an error queue, destination queue may be down.
    
    
    class Transporter
        
        def getValue( name, default=nil )
            value = ( ENV[name].nil?  || ENV[name] == '') ? default : ENV[name];
            RServiceBus.log "Env value: #{name}: #{value}"
            return value
        end
        
        def connectToSourceBeanstalk
            sourceQueueName = getValue( 'SOURCE_QUEUE_NAME', 'transport-out')
            sourceUrl = getValue( 'SOURCE_URL', '127.0.0.1:11300')
            @source = Beanstalk::Pool.new([sourceUrl])
            @source.watch sourceQueueName
            
            RServiceBus.log "Connected to, #{sourceQueueName}@#{sourceUrl}"
            
            rescue Exception => e
            puts 'Error connecting to Beanstalk'
            puts "Host string, #{sourceUrl}"
            if e.message == 'Beanstalk::NotConnected' then
                puts '***Most likely, beanstalk is not running. Start beanstalk, and try running this again.'
                puts "***If you still get this error, check beanstalk is running at, #{sourceUrl}"
                else
                puts e.message
                puts e.backtrace
            end
            abort();
        end
        
        
        def disconnect
            RServiceBus.log "Disconnect from, #{@remoteUserName}@#{@remoteHostName}/#{@remoteQueueName}"
            @gateway.shutdown! unless @gateway.nil?
            @gateway = nil
            @remoteHostName = nil
            
            @destination.close unless @destination.nil?
            @destination = nil
            
            @remoteUserName = nil
            @remoteQueueName = nil
        end
        
        
        def connect( remoteHostName )
            RServiceBus.rlog "connect called, #{remoteHostName}"
            if @gateway.nil? || remoteHostName != @remoteHostName || @destination.nil? then
                self.disconnect
            end
            
            if @gateway.nil? then
                #Get destination url from job
                @remoteHostName = remoteHostName
                @remoteUserName = getValue( "REMOTE_USER_#{remoteHostName.upcase}" )
                if @remoteUserName.nil? then
                    RServiceBus.log "**** Username not specified for Host, #{remoteHostName}"
                    RServiceBus.log "**** Add an environment variable of the form, REMOTE_USER_#{remoteHostName.upcase}=[USERNAME]"
                    abort()
                end
                
                @localPort = getValue( 'LOCAL_PORT', 27018 ).to_i
                RServiceBus.rlog "Local Port: #{@localPort}"
                
                begin
                    RServiceBus.log "Connect SSH, #{@remoteUserName}@#{@remoteHostName}"
                    # Open port 27018 to forward to 127.0.0.11300 on the remote host
                    @gateway = Net::SSH::Gateway.new(@remoteHostName, @remoteUserName)
                    @gateway.open('127.0.0.1', 11300, @localPort)
                    RServiceBus.log "Connected to SSH, #{@remoteUserName}@#{@remoteHostName}"
                    
                    rescue Errno::EADDRINUSE => e
                    puts "*** Local transport port in use, #{@localPort}"
                    puts "*** Change local transport port, #{@localPort}, using format, LOCAL_PORT=#{@localPort+1}"
                    abort()
                    rescue Errno::EACCES => e
                    puts "*** Local transport port specified, #{@localPort}, needs sudo access"
                    puts '*** Change local transport port using format, LOCAL_PORT=27018'
                    abort()
                    
                end
                
                begin
                    destinationUrl = "127.0.0.1:#{@localPort}"
                    RServiceBus.rlog "Connect to Remote Beanstalk, #{destinationUrl}"
                    @destination = Beanstalk::Pool.new([destinationUrl])
                    RServiceBus.rlog "Connected to Remote Beanstalk, #{destinationUrl}"
                    rescue Exception => e
                    if e.message == 'Beanstalk::NotConnected' then
                        puts "***Could not connect to destination, check beanstalk is running at, #{destinationUrl}"
                        raise CouldNotConnectToDestination.new
                    end
                    raise
                end
            end
        end
        
        def process
            #Get the next job from the source queue
            job = @source.reserve @timeout
            msg = YAML::load(job.body)
            
            self.connect( msg.remoteHostName )
            
            @remoteQueueName = msg.remoteQueueName
            RServiceBus.rlog "Put msg, #{msg.remoteQueueName}"
            @destination.use( msg.remoteQueueName )
            @destination.put( job.body )
            RServiceBus.log "Msg put, #{msg.remoteQueueName}"

            unless ENV['AUDIT_QUEUE_NAME'].nil? then
              @source.use ENV['AUDIT_QUEUE_NAME']
              @source.put job.body
            end
            #removeJob
            job.delete
            
            RServiceBus.log "Job sent to, #{@remoteUserName}@#{@remoteHostName}/#{@remoteQueueName}"
            
            
            rescue Exception => e
            self.disconnect
            if e.message == 'TIMED_OUT' then
                RServiceBus.rlog 'No Msg'
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

