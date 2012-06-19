class HelloWorld
	attr_reader :id, :name
	def initialize( id, name )
		@id = id
		@name = name
	end

end

class HelloWorldUpdated
	attr_reader :id
	def initialize( id )
		@id = id
	end

end
