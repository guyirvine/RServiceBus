
class MessageHandler_PerfTest

	attr_accessor :Bus

	def initialize
		@count = 0
		@start = Time.now
	end

	def Handle( msg )
		@count = @count + 1
		if @count % 1000 == 0 then
			finish = Time.now
			elapsed = (finish - @start) * 1000
			puts "Done: #{elapsed}"
			@start = Time.now	
		end
	end
end
