module RServiceBus
    
    require "FluidDb/TinyTds"
    
    #Implementation of an AppResource - Redis
    class AppResource_FluidDbTinyTds<AppResource
        
        def connect(uri)
            return FluidDb::TinyTds.new( uri )
        end
    end
end
