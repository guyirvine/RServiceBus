module RServiceBus
    
    class AppResource_File<AppResource
        
        @file
        
        def connect()
            @file = File.new( @uri.path )
            
            puts "AppResource_File. Connected to, " + @uri.to_s
        end
        
        def initialize( uri )
            super(uri)
            self.connect
        end
        
        def getResource
            return @file
        end
        
    end
    
end
