module RServiceBus
    
    require "FluidDb/Mysql"
    
    #Implementation of an AppResource - Redis
    class AppResource_FluidDbMysql<AppResource
        
        def connect(uri)
            return FluidDb::Mysql.new( uri )
        end
        
    end
    
end
