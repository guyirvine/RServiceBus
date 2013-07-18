require 'net/scp'

module RServiceBus

    class ScpUploadHelper
        attr_reader :uri
        
        def initialize( uri )
            @uri = uri
        end
        
        def upload( source )
            #opportunity for smarts here. Could tar zip if it was a directory of files

            Net::SCP.upload!(@uri.host, @uri.user, source, @uri.path )
        end
        
        def close
        end

    end

    class AppResource_ScpUpload<AppResource
        
        def connect(uri)
            return ScpUploadHelper.new( uri )
            
            return inputDir;
        end
        
    end
    
end
