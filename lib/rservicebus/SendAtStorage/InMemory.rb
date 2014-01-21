module RServiceBus
    
    class SendAtStorage_File
        
        def initialize( uri )
            @list = Array.new
        end

        #Add
        def Add( msg )
            @list << msg
        end

        #GetAll
        def GetAll
            return @list
        end

        #Delete
        def Delete( idx )
            @list.delete_at( idx )
        end

    end
end

