module RServiceBus
    
    require "uri"
    
    #Configure AppResources for an rservicebus host
    class ConfigureAppResource
        
        def getResources( env )
            resources = Hash.new
            
            env.each do |k,v|
                if v.is_a?(String) and
					k.start_with?( "RSB_" ) then
                    uri = URI.parse( v )
                    case uri.scheme
                        when "redis"
						resources[k.sub( "RSB_", "" )] = AppResource_Redis.new( uri )
                        
                        when "mysql"
                        resources[k.sub( "RSB_", "" )] = AppResource_Mysql.new( uri )
                        else
						abort("Scheme, #{uri.scheme}, not recognised when configuring app resource, #{k}=#{v}");
                    end
                end
                
            end
            
            return resources
        end
        
    end
    
end
