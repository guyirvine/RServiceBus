require "uuidtools"
require "yaml"


class RServiceBus_Messages

	def initialize()
		msgs = Array.new
	end
	
	def addMsg( msg )
		msgs.add( msg )
	end

end


class RServiceBus_ErrorMessage

	attr_reader :sourceQueue, :errorMsg

	def initialize( sourceQueue, errorMsg )
		@sourceQueue=sourceQueue
		@errorMsg=errorMsg
	end

end


class RServiceBus_Message

	attr_reader :returnAddress, :msgId, :errorMsg

	def initialize( msg, returnAddress )
		@_msg=YAML::dump(msg)
		@returnAddress=returnAddress
		
		@msgId=UUIDTools::UUID.random_create
		@errorMsg = nil
	end

	def addErrorMsg( sourceQueue, e )
		errorString = e.message + ". " + e.backtrace[0]
		puts errorString

		@errorMsg = RServiceBus_ErrorMessage.new( sourceQueue, errorString )
	end

	def msg
		return YAML::load( @_msg )
	end

end
