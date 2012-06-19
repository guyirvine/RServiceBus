require 'test/unit'
require './Contract'
require './MessageHandler/HelloWorld'

require "rservicebus"
require "rservicebus/Test"

class HelloWorldTest < Test::Unit::TestCase

		@Bus
		@Redis
		@Handler

		def setup()
			super()


        	@Bus = RServiceBus::Test_Bus.new
        	@Redis = RServiceBus::Test_Redis.new

        	@Handler = MessageHandler_HelloWorld.new
        	@Handler.Bus = @Bus
        	@Handler.Redis = @Redis
        	
			@Redis.set "id:1", "One"

		end

        def test_Set
        	@BaseMsg = HelloWorld.new( 1, "Two" );

        	assert_equal "One", @Redis.get( "id:1" )
        	assert_equal 0, @Bus.publishList.length

        	@Handler.Handle( @BaseMsg );
        	assert_equal "Two", @Redis.get( "id:1" )
        	assert_equal 1, @Bus.publishList.length
        end

end

