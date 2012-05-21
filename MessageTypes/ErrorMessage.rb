class ErrorMessage

	attr_reader :msg, :sourceQueue, :errorMsg

	def initialize( msg, sourceQueue, errorMsg )
		@msg=msg
		@sourceQueue=sourceQueue
		@errorMsg=errorMsg
	end

end
