module RServiceBus

    require "uri"

    #Configure AppResources for an rservicebus host
    class ConfigureAppResource

        def getResources( env, host, stateManager, sagaStorage )
            resourceManager = ResourceManager.new( stateManager, sagaStorage )


            env.each do |k,v|
                if v.is_a?(String) and
					k.start_with?( "RSBFDB_" ) then
                    uri = URI.parse( v )
                    require "rservicebus/AppResource/FluidDb"
                    resourceManager.add k.sub( "RSBFDB_", "" ), AppResource_FluidDb.new( host, uri )
                elsif v.is_a?(String) and
					k.start_with?( "RSB_" ) then
                    uri = URI.parse( v )
                    case uri.scheme
                        when "redis"
                    require "rservicebus/AppResource/Redis"
						resourceManager.add k.sub( "RSB_", "" ), AppResource_Redis.new( host, uri )

                        when "mysql"
                        require "rservicebus/AppResource/Mysql"
                        resourceManager.add k.sub( "RSB_", "" ), AppResource_Mysql.new( host, uri )

                        when "fluiddbmysql"
                        require "rservicebus/AppResource/FluidDbMysql"
                        resourceManager.add k.sub( "RSB_", "" ), AppResource_FluidDbMysql.new( host, uri )
                        when "fluiddbmysql2"
                        require "rservicebus/AppResource/FluidDbMysql2"
                        resourceManager.add k.sub( "RSB_", "" ), AppResource_FluidDbMysql2.new( host, uri )
                        when "fluiddbpgsql"
                        require "rservicebus/AppResource/FluidDbPgsql"
                        resourceManager.add k.sub( "RSB_", "" ), AppResource_FluidDbPgsql.new( host, uri )
                        when "fluiddbtinytds"
                        require "rservicebus/AppResource/FluidDbTinyTds"
                        resourceManager.add k.sub( "RSB_", "" ), AppResource_FluidDbTinyTds.new( host, uri )

                        when "fluiddbfirebird"
                        require "rservicebus/AppResource/FluidDbFirebird"
                        resourceManager.add k.sub( "RSB_", "" ), AppResource_FluidDbFirebird.new( host, uri )

                        when "dir"
                        require "rservicebus/AppResource/Dir"
                        resourceManager.add k.sub( "RSB_", "" ), AppResource_Dir.new( host, uri )
                        when "file"
                        require "rservicebus/AppResource/File"
                        resourceManager.add k.sub( "RSB_", "" ), AppResource_File.new( host, uri )
                        when "scpdownload"
                        require "rservicebus/AppResource/ScpDownload"
                        resourceManager.add k.sub( "RSB_", "" ), AppResource_ScpDownload.new( host, uri )
                        when "scpupload"
                        require "rservicebus/AppResource/ScpUpload"
                        resourceManager.add k.sub( "RSB_", "" ), AppResource_ScpUpload.new( host, uri )
                        when "smbfile"
                        require "rservicebus/AppResource/SmbFile"
                        resourceManager.add k.sub( "RSB_", "" ), AppResource_SmbFile.new( host, uri )
                        else
						abort("Scheme, #{uri.scheme}, not recognised when configuring app resource, #{k}=#{v}");
                    end
                end

            end

            return resourceManager
        end

    end

end
