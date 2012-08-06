module RServiceBus
    
    require "FluidDb/Pgsql"
    
    #Implementation of an AppResource - Redis
    class AppResource_FluidDbPgsql<AppResource
        
        @connection

        def initialize( uri )
            super(uri)
            host = uri.host
            database = uri.path.sub( "/", "" )
            
            
            @connection = FluidDb::Pgsql.new( uri )
            puts "AppResource_Mysql. Connected to, " + uri.to_s
        end

        def getResource
            return @connection
        end
        
    end
    
end
