module RServiceBus
    
    require "uri"
    
    #Configure AppResources for an rservicebus host
    class ConfigureAppResource

        def getResources( env, host )
            resources = Hash.new

            env.each do |k,v|
                if v.is_a?(String) and
					k.start_with?( "RSB_" ) then
                    uri = URI.parse( v )
                    case uri.scheme
                        when "redis"
						resources[k.sub( "RSB_", "" )] = AppResource_Redis.new( host, uri )
                        
                        when "mysql"
                        require "rservicebus/AppResource/Mysql"
                        resources[k.sub( "RSB_", "" )] = AppResource_Mysql.new( host, uri )
                        
                        when "fluiddbmysql"
                        require "rservicebus/AppResource/FluidDbMysql"
                        resources[k.sub( "RSB_", "" )] = AppResource_FluidDbMysql.new( host, uri )
                        when "fluiddbmysql2"
                        require "rservicebus/AppResource/FluidDbMysql2"
                        resources[k.sub( "RSB_", "" )] = AppResource_FluidDbMysql2.new( host, uri )
                        when "fluiddbpgsql"
                        require "rservicebus/AppResource/FluidDbPgsql"
                        resources[k.sub( "RSB_", "" )] = AppResource_FluidDbPgsql.new( host, uri )
                        when "fluiddbtinytds"
                        require "rservicebus/AppResource/FluidDbTinyTds"
                        resources[k.sub( "RSB_", "" )] = AppResource_FluidDbTinyTds.new( host, uri )

                        when "fluiddbfirebird"
                        require "rservicebus/AppResource/FluidDbFirebird"
                        resources[k.sub( "RSB_", "" )] = AppResource_FluidDbFirebird.new( host, uri )
                        
                        when "dir"
                        require "rservicebus/AppResource/Dir"
                        resources[k.sub( "RSB_", "" )] = AppResource_Dir.new( host, uri )
                        when "file"
                        require "rservicebus/AppResource/File"
                        resources[k.sub( "RSB_", "" )] = AppResource_File.new( host, uri )
                        when "scpupload"
                        require "rservicebus/AppResource/ScpUpload"
                        resources[k.sub( "RSB_", "" )] = AppResource_ScpUpload.new( host, uri )
                        else
						abort("Scheme, #{uri.scheme}, not recognised when configuring app resource, #{k}=#{v}");
                    end
                end
                
            end
            
            return resources
        end
        
    end
    
end
