module RServiceBus

    class StateStorage

        def StateStorage.Get( uri )
            case uri.scheme
                when 'dir'
                    require 'rservicebus/StateStorage/Dir.rb'
                    return StateStorage_Dir.new( uri )
                    when 'inmem'
                    require 'rservicebus/StateStorage/InMemory.rb'
                    return StateStorage_InMemory.new( uri )
                else
                    abort("Scheme, #{uri.scheme}, not recognised when configuring StateStorage, #{uri.to_s}");
            end
            
        end
        
        
    end

end
