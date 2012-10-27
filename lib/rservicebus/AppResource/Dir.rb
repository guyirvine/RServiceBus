module RServiceBus
    
    class AppResource_Dir<AppResource
        
        @dir
        
        def connect()
            @dir = Dir.new( @uri.path )
            
            puts "AppResource_Dir. Connected to, " + @uri.to_s
        end
        
        def initialize( uri )
            super(uri)
            self.connect
        end
        
        def getResource
            return @dir
        end
        
    end
    
end
