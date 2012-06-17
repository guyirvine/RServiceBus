require "./Contract.rb"

class MessageHandler_PerfTest

	attr_writer :Bus
	attr_reader :Bus
	@Bus

	@count
	@start

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
