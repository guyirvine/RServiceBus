module RServiceBus

class UserMessage_WithPayload

	attr_reader :payload

	def initialize( payload )
		@payload = payload
	end

end

end

