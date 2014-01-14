module RServiceBus
    
    class SagaStorage
        
        def SagaStorage.Get( uri )
            case uri.scheme
                when "dir"
                require "rservicebus/SagaStorage/Dir"
                return SagaStorage_Dir.new( uri )
                when "inmem"
                require "rservicebus/SagaStorage/InMemory"
                return SagaStorage_InMemory.new( uri )
                else
                abort("Scheme, #{uri.scheme}, not recognised when configuring SagaStorage, #{uri.to_s}");
            end
            
        end
        
    end
    
end
