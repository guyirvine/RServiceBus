module RServiceBus
    
    require 'rservicebus/StateStorage'
    
    class StateManager


        def Required
            #Check if the State Dir has been specified
            #If it has, make sure it exists, and is writable

            string = RServiceBus.getValue( "STATE_URI" )
            if string.nil? then
                string = "dir:///tmp"
            end
            
            uri = URI.parse( string )
            @stateStorage = StateStorage.Get( uri )
            
        end
        
        #Start
        def Begin
            @stateStorage.Begin
        end

        #Get
        def Get( handler )
            return @stateStorage.Get( handler )
        end
        
        #Finish
        def Commit
            @stateStorage.Commit
        end


    end
    
    
end
