module RServiceBus

class ErrorMessage

	attr_reader :sourceQueue, :errorMsg

	def initialize( sourceQueue, errorMsg )
		@sourceQueue=sourceQueue
		@errorMsg=errorMsg
	end

end

end