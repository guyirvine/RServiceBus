module RServiceBus
    
    require "FluidDb/Firebird"
    
    #Implementation of an AppResource - Redis
    class AppResource_FluidDbFirebird<AppResource

        def connect(uri)
            return FluidDb::Firebird.new( uri )
        end

        # Transaction Semantics
        def Begin
            @connection.connection.transaction()
        end

        # Transaction Semantics
        def Commit
            @connection.connection.commit()
        end

        # Transaction Semantics
        def Rollback
            @connection.connection.rollback()
        end
        
    end
end
