require "uri"
require "redis"

class AppResource
	@uri

	def initialize( uri )
		@uri = uri
	end

	def getResource
		raise "Method, getResource, needs to be implemented for resource"
	end
end

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

class ConfigureAppResource

	def getResources( env )
		resources = Hash.new

		env.each do |k,v|
			if v.is_a?(String) and
					k.start_with?( "RSB_" ) then
				uri = URI.parse( v )
				case uri.scheme
					when "redis"
						resources[k.sub( "RSB_", "" )] = RedisAppResource.new( uri )
					else
						abort("Scheme, #{uri.scheme}, not recognised when configuring app resource, #{k}=#{v}");
				end
			end
					
		end

		return resources
	end

end
