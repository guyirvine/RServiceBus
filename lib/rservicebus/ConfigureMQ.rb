module RServiceBus
    
    require "uri"
    
    #Configure AppResources for an rservicebus host
    class ConfigureMQ
        
        def get( string, timeout )

            uri = URI.parse( string )
            case uri.scheme
                when "beanstalk"
                require "rservicebus/MQ/Beanstalk"
                mq = MQ_Beanstalk.new( uri, timeout )

                when "bunny"
                require "rservicebus/MQ/Bunny"
                mq = MQ_Bunny.new( uri, timeout )

                else
                abort("Scheme, #{uri.scheme}, not recognised when configuring mq, #{string}");
            end
            
            return mq
        end
        
    end
    
end
