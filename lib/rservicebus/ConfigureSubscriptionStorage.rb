module RServiceBus
    
    require 'uri'
    
    #Configure SubscriptionStorage for an rservicebus host
    class ConfigureSubscriptionStorage
        
        def get( appName, uri_string )
            uri = URI.parse( uri_string )
            
            case uri.scheme
                when 'redis'
                require 'rservicebus/SubscriptionStorage/Redis'
                s = SubscriptionStorage_Redis.new( appName, uri )
                
                when 'file'
                require 'rservicebus/SubscriptionStorage/File'
                s = SubscriptionStorage_File.new( appName, uri )
                
                else
                abort("Scheme, #{uri.scheme}, not recognised when configuring subscription storage, #{uri_string}");
            end
            return s
        end
        
    end
    
end
