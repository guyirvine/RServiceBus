module RServiceBus
    
    require 'FluidDb/Db'
    
    #Implementation of an AppResource - Redis
    class AppResource_FluidDb<AppResource
        
        def connect(uri)
            return FluidDb::Db( uri )
        end

        # Transaction Semantics
        def Begin
            @connection.Begin
        end

        # Transaction Semantics
        def Commit
            @connection.Commit
        end

        # Transaction Semantics
        def Rollback
            @connection.Rollback
        end
        
    end
end
