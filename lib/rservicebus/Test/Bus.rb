module RServiceBus

class Test_Bus
	attr_accessor :publishList, :sendList
	@publishList
	@sendList
	
	def initialize
		@publishList = Array.new
		@sendList = Array.new
	end

	def Publish( msg )
		@publishList << msg
	end

	def Send( msg )
		@sendList << msg
	end
end

end


