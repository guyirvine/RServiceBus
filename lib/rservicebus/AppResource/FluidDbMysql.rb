module RServiceBus
    
    require "FluidDb/Mysql"
    
    #Implementation of an AppResource - Redis
    class AppResource_FluidDbMysql<AppResource
        
        @connection
        
        def initialize( uri )
            super(uri)
            host = uri.host
            database = uri.path.sub( "/", "" )
            
            
            @connection = FluidDb::Mysql.new( uri )
            puts "AppResource_Mysql. Connected to, " + uri.to_s
        end
        
        def getResource
            return @connection
        end
        
    end
    
end
