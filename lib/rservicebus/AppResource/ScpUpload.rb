require 'net/scp'
require 'net/sftp'

module RServiceBus

    class ScpUploadHelper
        attr_reader :uri
        
        def initialize( uri )
            @uri = uri
        end
        
        def upload( source )
            #opportunity for smarts here. Could tar zip if it was a directory of files

#            Net::SCP.upload!(@uri.host, @uri.user, source, @uri.path, :recursive )
		RServiceBus.log "Host: #{@uri.host}, User: #{@uri.user}, Source: #{source}, Destination: #{@uri.path}", true
		Net::SSH.start( @uri.host, @uri.user ) do|ssh|
			ssh.scp.upload!( source, @uri.path, :recursive => true )
		end

        end
        
        def close
        end

        def delete( path, filepattern )
            RServiceBus.log "Host: #{@uri.host}, User: #{@uri.user}, File Pattern: #{filepattern}, Destination: #{@uri.path}", true
            Net::SSH.start( @uri.host, @uri.user ) do |ssh|
                ssh.sftp.connect do |sftp|
                    files = sftp.dir.glob(path, filepattern)
                    sftp.dir.foreach(path){
                        |file|
                        sftp.remove("#{path}/#{file.name}")
                    }
                end
            end
        end

    end

    class AppResource_ScpUpload<AppResource
        
        def connect(uri)
            return ScpUploadHelper.new( uri )
            
            return inputDir;
        end
        
    end
    
end
