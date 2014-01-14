module RServiceBus
    
    
    class Saga_Data
        attr_reader :correlationId, :sagaClassName
        attr_accessor :finished

        def initialize( saga )
            @createdAt = DateTime.now
            @correlationId = UUIDTools::UUID.random_create
            @sagaClassName = saga.class.name
            @finished = false
            
            @hash = {}
        end
        
        def method_missing(name, *args, &block)
            @hash.send(name, *args, &block)
        end
        
    end
    
    
end

