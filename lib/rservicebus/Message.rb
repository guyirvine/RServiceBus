module RServiceBus

class Message

	attr_reader :returnAddress, :msgId

	def initialize( msg, returnAddress )
		@_msg=YAML::dump(msg)
		@returnAddress=returnAddress
		
		@msgId=UUIDTools::UUID.random_create
		@errorList = Array.new
	end

	def addErrorMsg( sourceQueue, errorString )
		@errorList << RServiceBus::ErrorMessage.new( sourceQueue, errorString )
	end

	def getLastErrorMsg
		return @errorList.last
	end

	def msg
		return YAML::load( @_msg )
	end

end

end