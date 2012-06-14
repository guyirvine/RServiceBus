require "redis"

class RedisAppResource<AppResource

	@connection

	def initialize( uri )
		super(uri)
		@connection = Redis.new
	end

	def getResource
		return @connection
	end

end
