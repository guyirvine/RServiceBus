module RServiceBus
    
    require "FluidDb/Pgsql"
    
    #Implementation of an AppResource - Redis
    class AppResource_FluidDbPgsql<AppResource
        
        def connect(uri)
            return FluidDb::Pgsql.new( uri )
        end
    end
end
