module RServiceBus

class ErrorMessage

	attr_reader :occurredAt, :sourceQueue, :errorMsg

	def initialize( sourceQueue, errorMsg )
		@occurredAt = DateTime.now

		@sourceQueue=sourceQueue
		@errorMsg=errorMsg
	end

end

end