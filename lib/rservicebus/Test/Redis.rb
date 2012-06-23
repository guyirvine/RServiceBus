module RServiceBus

class Test_Redis

	@keyHash

	def initialize
		@keyHash = Hash.new
	end

	def get( key )
		return @keyHash[key]
	end
	
	def set( key, value )
		@keyHash[key] = value
	end

	def sadd( key, value )
		if @keyHash[key].nil? then
			@keyHash[key] = Array.new
		end
		@keyHash[key] << value
	end
	
	def smembers( key )
		return @keyHash[key]
	end

	def incr( key )
		if !@keyHash.has_key?( key ) then
			@keyHash[key] = 0
		end

		@keyHash[key] = @keyHash[key] + 1
		return @keyHash[key]
	end
end

end