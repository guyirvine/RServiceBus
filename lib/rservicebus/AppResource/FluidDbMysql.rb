module RServiceBus
    
    require 'FluidDb/Mysql'
    
    #Implementation of an AppResource - Redis
    class AppResource_FluidDbMysql<AppResource
        
        def connect(uri)
            return FluidDb::Mysql.new( uri )
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
