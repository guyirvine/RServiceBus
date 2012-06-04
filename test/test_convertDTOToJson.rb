require 'test/unit'
require 'rservicebus'


class HelloWorld
	attr_reader :foo1, :foo2
	def initialize( foo1, foo2 )
		@foo1 = foo1
		@foo2 = foo2
	end
end


class ConvertDTOToJSONTest < Test::Unit::TestCase
  def test_standard
  	helloWorld = HelloWorld.new( "bar1", "bar2" )
    assert_equal "{\"foo1\":\"bar1\",\"foo2\":\"bar2\"}",
      RServiceBus.convertDTOToJson( helloWorld )
  end

end
