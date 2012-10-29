module RServiceBus
    
    require "FluidDb/Mysql2"
    
    #Implementation ofF an AppResource - Redis
    class AppResource_FluidDbMysql2<AppResource
        
        def connect(uri)
            return FluidDb::Mysql2.new( uri )
        end

    end
    
end
