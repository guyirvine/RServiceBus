module RServiceBus
    
    require 'FluidDb/Mysql2'
    
    #Implementation ofF an AppResource - Redis
    class AppResource_FluidDbMysql2<AppResource
        
        def connect(uri)
            return FluidDb::Mysql2.new( uri )
        end

        # Transaction Semantics
        def Begin
            @connection.execute( 'BEGIN', [] )
        end
        
        # Transaction Semantics
        def Commit
            @connection.execute( 'COMMIT', [] )
        end
        
        # Transaction Semantics
        def Rollback
            @connection.execute( 'ROLLBACK', [] )
        end
        
    end
    
end
