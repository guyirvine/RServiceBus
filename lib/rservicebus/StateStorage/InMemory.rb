module RServiceBus
    
    class StateStorage_InMemory
        
        def initialize( uri )
            @hash = Hash.new
        end
        
        #Start
        def Begin
            @list = Array.new
        end
        
        #Get
        def Get( handler )
            hash = @hash[handler.class.name]
            @list << Hash["name", handler.class.name, "hash", hash]

            return hash
        end
        
        #Finish
        def Commit
            @list.each do |e|
                @hash[ e['name'] ] = e['hash']
            end
        end
        
    end
    
end
