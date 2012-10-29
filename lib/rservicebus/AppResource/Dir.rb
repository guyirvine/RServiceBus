module RServiceBus
    
    class AppResource_Dir<AppResource
        
        def connect(uri)
            return Dir.new( uri.path )
        end
        
    end
    
end
