module RServiceBus
    
    require "beanstalk-client"
    require "rservicebus/MQ"
    
    # Beanstalk client implementation.
    #
    class MQ_Beanstalk<MQ
        
        # Connect to the broker
        #
        def connect( host, port )
            port ||= 11300
            string = "#{host}:#{port}"

            begin
                @beanstalk = Beanstalk::Pool.new([string])
                
                current = @beanstalk.stats["max-job-size"]
                if current < 4194304 then
                    puts "***WARNING: Lowest recommended.max-job-size is 4m, current max-job-size, #{current.to_f / (1024*1024)}m"
                    puts "***WARNING: Set the job size with the -z switch, eg /usr/local/bin/beanstalkd -z 4194304"
                end
                rescue Exception => e
                puts "Error connecting to Beanstalk"
                puts "Host string, #{string}"
                if e.message == "Beanstalk::NotConnected" then
                    puts "***Most likely, beanstalk is not running. Start beanstalk, and try running this again."
                    puts "***If you still get this error, check beanstalk is running at, #{string}"
                    else
                    puts e.message
                    puts e.backtrace
                end
                abort()
            end
        end
        
        # Connect to the queue
        #
        def subscribe( queuename )
            @beanstalk.watch( queuename )
        end
        
        # Get next msg from queue
        def pop
            begin
                @job = @beanstalk.reserve @timeout
                rescue Exception => e
                if e.message == "TIMED_OUT" then
                    raise NoMsgToProcess.new
                end
                raise e
            end
            return @job.body
        end

        def returnToQueue
            @job.release
            
            end
        
        # "Commit" queue
        def ack
            @job.delete
            @job = nil;
        end
        
        # At least called in the Host rescue block, to ensure all network links are healthy
        def send( queueName, msg )
            @beanstalk.use( queueName )
            @beanstalk.put( msg )
        end
        
    end
end
