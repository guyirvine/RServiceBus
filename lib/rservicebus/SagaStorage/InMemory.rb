module RServiceBus


class SagaStorage_InMemory
    
        def initialize( uri )
        end

        #Start
        def Begin
            @hash = Hash.new
            @deleted = Array.new
        end
        
        #Set
        def Set( data )
            @hash[data.correlationId] = data
        end

        #Get
        def Get( correlationId )
            return @hash[correlationId]
        end
        
        #Finish
        def Commit
            @deleted.each do |correlationId|
                @hash.delete( correlationId )
            end
        end
        
        def Delete( correlationId )
            @deleted << correlationId
        end

        def Rollback
        end

    end

end
