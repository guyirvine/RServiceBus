module RServiceBus

#This is the top level message that is passed around the bus
class Message

	attr_reader :returnAddress, :msgId

# Constructor
#
# @param [Object] msg The calling function msg to be sent
# @param [Object] returnAddress A queue that the receiving message handler can send replies to
	def initialize( msg, returnAddress )
		@_msg=YAML::dump(msg)
		@returnAddress=returnAddress
		
		@msgId=UUIDTools::UUID.random_create
		@errorList = Array.new
	end

# Capture information when an exception has occurred, to help with diagnosing the error.
# Once the error has been diagnosed, the msg may be able to be returned to the sourceQueue
#
# @param [Object] sourceQueue The name of the queue to return the msg to
# @param [Object] errorString A queue that the receiving message handler can send replies to
	def addErrorMsg( sourceQueue, errorString )
		@errorList << RServiceBus::ErrorMessage.new( sourceQueue, errorString )
	end

# Convenience function
#
# @return [String] 
	def getLastErrorMsg
		return @errorList.last
	end

	def msg
		return YAML::load( @_msg )
	end

end

end