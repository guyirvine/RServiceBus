require "uri"

# Wrapper base class for resources used by applications, allowing rservicebus to configure the resource
# - dependency injection.
#
class AppResource
	@uri

# Resources are attached resources, and can be specified using the URI syntax.
#
# @param [String] uri a location for the resource to which we will attach, eg redis://127.0.0.1/foo
	def initialize( uri )
		@uri = uri
	end

# The method which actually configures the resource.
#
# @return [Object] the configured object.	
	def getResource
		raise "Method, getResource, needs to be implemented for resource"
	end
end
