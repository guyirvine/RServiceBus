module RServiceBus

class Test_Bus
	attr_accessor :publishList, :sendList, :replyList, :logList
	@publishList
	@sendList
	@replyList
	@logList

	def initialize
		@publishList = Array.new
		@sendList = Array.new
		@replyList = Array.new
		@logList = Array.new
	end

	def Publish( msg )
		@publishList << msg
	end

	def Send( msg )
		@sendList << msg
	end

	def Reply( msg )
		@replyList << msg
	end

	def log( string, verbose=false )
		item = Hash.new
		item["string"] = string
		item["verbose"] = verbose
		@logList << item
	end
end

end


