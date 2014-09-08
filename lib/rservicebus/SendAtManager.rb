module RServiceBus
    
    require 'rservicebus/SendAtStorage'
    
    class SendAtManager


        def initialize( bus )
            #Check if the SendAt Dir has been specified
            #If it has, make sure it exists, and is writable

            string = RServiceBus.getValue('SENDAT_URI')
            if string.nil? then
                string = 'file:///tmp/rservicebus-sendat'
            end

            uri = URI.parse( string )
            @SendAtStorage = SendAtStorage.Get( uri )

            @Bus = bus
        end


        def Process
            now = DateTime.now
            @SendAtStorage.GetAll.each_with_index do |row,idx|
                if row['timestamp'] > now then
                    @Bus._SendNeedsWrapping( row['msg'], row['queueName'], row['correlationId'] )
                    @SendAtStorage.Delete( idx )
                end
            end
        end

        def Add( row )
            @SendAtStorage.Add( row )
        end


    end


end
