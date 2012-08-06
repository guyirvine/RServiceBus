module RServiceBus
    
    require "FluidDb/Mysql2"
    
    #Implementation ofF an AppResource - Redis
    class AppResource_FluidDbMysql2<AppResource
        
        @connection

        def initialize( uri )
            super(uri)
            host = uri.host
            database = uri.path.sub( "/", "" )
            
            
            @connection = FluidDb::Mysql2.new( uri )
            puts "AppResource_Mysql. Connected to, " + uri.to_s
        end

        def getResource
            return @connection
        end
        
    end
    
end
