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
                        require "rservicebus/AppResource/Mysql"
                        resources[k.sub( "RSB_", "" )] = AppResource_Mysql.new( uri )
                        
                        when "fluiddbmysql"
                        require "rservicebus/AppResource/FluidDbMysql"
                        resources[k.sub( "RSB_", "" )] = AppResource_FluidDbMysql.new( uri )
                        when "fluiddbmysql2"
                        require "rservicebus/AppResource/FluidDbMysql2"
                        resources[k.sub( "RSB_", "" )] = AppResource_FluidDbMysql2.new( uri )
                        when "fluiddbpgsql"
                        require "rservicebus/AppResource/FluidDbPgsql"
                        resources[k.sub( "RSB_", "" )] = AppResource_FluidDbPgsql.new( uri )
                        when "fluiddbtinytds"
                        require "rservicebus/AppResource/FluidDbTinyTds"
                        resources[k.sub( "RSB_", "" )] = AppResource_FluidDbTinyTds.new( uri )
                        when "dir"
                        require "rservicebus/AppResource/Dir"
                        resources[k.sub( "RSB_", "" )] = AppResource_Dir.new( uri )
                        when "file"
                        require "rservicebus/AppResource/File"
                        resources[k.sub( "RSB_", "" )] = AppResource_File.new( uri )
                        else
						abort("Scheme, #{uri.scheme}, not recognised when configuring app resource, #{k}=#{v}");
                    end
                end
                
            end
            
            return resources
        end
        
    end
    
end
