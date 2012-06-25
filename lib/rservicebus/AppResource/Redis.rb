require "redis"

#Implementation of an AppResource - Redis
class AppResource_Redis<AppResource

	@connection

	def initialize( uri )
		super(uri)
		@connection = Redis.new
	end

	def getResource
		return @connection
	end

end
