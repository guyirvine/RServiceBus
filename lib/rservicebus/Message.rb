module RServiceBus
    
    require "zlib"
    require "yaml"
    require "uuidtools"

    #This is the top level message that is passed around the bus
    class Message
        
        attr_reader :returnAddress, :msgId, :remoteQueueName, :remoteHostName, :lastErrorSourceQueue, :lastErrorString, :correlationId
        
        # Constructor
        #
        # @param [Object] msg The msg to be sent
        # @param [Object] returnAddress A queue to which the destination message handler can send replies
        def initialize( msg, returnAddress, correlationId=nil )
            if ENV["RSBMSG_COMPRESS"].nil? then
                @compressed = false
                @_msg=YAML::dump(msg)
                else
                @compressed = true
                @_msg=Zlib::Deflate.deflate(YAML::dump(msg))
            end
            
            @correlationId = correlationId
            @returnAddress=returnAddress
            
            @createdAt = DateTime.now
            
            @msgId=UUIDTools::UUID.random_create
            @errorList = Array.new
        end
        
        # If an error occurs while processing the message, this method allows details of the error to held
        # next to the msg.
        #
        # Error(s) are held in an array, which allows current error information to be held, while still
        # retaining historical error messages.
        #
        # @param [Object] sourceQueue The name of the queue to which the msg should be returned
        # @param [Object] errorString A readible version of what occured
        def addErrorMsg( sourceQueue, errorString )
            @lastErrorSourceQueue = sourceQueue
            @lastErrorString = errorString
            
            @errorList << RServiceBus::ErrorMessage.new( sourceQueue, errorString )
        end
        
        def setRemoteHostName( hostName )
            @remoteHostName = hostName
        end
        
        def setRemoteQueueName( queueName )
            @remoteQueueName = queueName
        end
        
        
        # @return [Object] The msg to be sent
        def msg
            if @compressed == true then
                return YAML::load( Zlib::Inflate.inflate( @_msg ))
                else
                return YAML::load( @_msg )
            end
            rescue ArgumentError => e
            raise e if e.message.index( "undefined class/module " ).nil?
            
            puts e.message
            msg_name = e.message.sub( "undefined class/module ", "" )
            
            raise ClassNotFoundForMsg.new( msg_name )
        end
        
    end
    
end
