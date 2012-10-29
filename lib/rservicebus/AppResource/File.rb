module RServiceBus
    
    class AppResource_File<AppResource
        
        def connect(uri)
            return File.new( uri.path )
        end
        
    end
    
end
