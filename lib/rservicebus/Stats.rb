module RServiceBus

#Used to collect various run time stats for runtime reporting
class Stats

	def initialize
		@hash = Hash.new

		@totalProcessed = 0
		@totalErrored = 0
		@totalSent = 0
		@totalPublished = 0
		@totalReply = 0

		@totalByMessageType = Hash.new
	end

	def incTotalProcessed
		@totalProcessed = @totalProcessed + 1
	end

	def incTotalErrored
		@totalErrored = @totalErrored + 1
	end

	def incTotalSent
		@totalSent = @totalSent + 1
	end

	def incTotalPublished
		@totalPublished = @totalPublished + 1
	end

	def incTotalReply
		@totalReply = @totalReply + 1
	end

	def inc( key )
		if @hash[key].nil? then
			@hash[key] = 0
		end
		@hash[key] = @hash[key] + 1
	end

	def incMessageType( className )
		if @totalByMessageType[className].nil? then
			@totalByMessageType[className] = 1
		else
			@totalByMessageType[className] = @totalByMessageType[className] + 1
		end

	end

	def getForReporting
		string = "T:#{@totalProcessed};E:#{@totalErrored};S:#{@totalSent};P:#{@totalPublished};R:#{@totalReply}"

		if @hash.length > 0 then
			@hash.each do |k,v|
				string = "#{string};#{k}:#{v}"
			end
		end
		
		return string
	end

end


end
