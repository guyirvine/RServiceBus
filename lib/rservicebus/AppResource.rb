require "uri"

class AppResource
	@uri

	def initialize( uri )
		@uri = uri
	end

	def getResource
		raise "Method, getResource, needs to be implemented for resource"
	end
end
