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
            @stateStorage.Begin unless @stateStorage.nil?
        end

        #Get
        def Get( handler )
            return @stateStorage.Get( handler ) unless @stateStorage.nil?
        end
        
        #Finish
        def Commit
            @stateStorage.Commit unless @stateStorage.nil?
        end


    end
    
    
end
