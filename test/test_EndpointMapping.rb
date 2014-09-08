require 'test/unit'
require './lib/rservicebus/EndpointMapping.rb'


class Test_EndpointMapping<RServiceBus::EndpointMapping

    attr_reader :endpoints
    
	def initialize
        super
		@valueList = Hash.new
	end

	def getValue( name, default=nil )
		value = ( @valueList[name].nil? || @valueList[name] == '') ? default : @valueList[name];
		return value
	end

	def setValue( name, value )
		@valueList[name] = value
	end

    def log( string, ver=false )
    end

end

class EndpointMappingTest < Test::Unit::TestCase

	def test_loadMessageEndpointMappings_empty
		config = Test_EndpointMapping.new

		config.setValue( 'MESSAGE_ENDPOINT_MAPPINGS', '')
		config.Configure('localQueueName')

		assert_equal 0, config.endpoints.length
	end

	def test_loadMessageEndpointMappings_single_without_seperator
		config = Test_EndpointMapping.new

		config.setValue( 'MESSAGE_ENDPOINT_MAPPINGS', 'msg:endpoint')
		config.Configure('localQueueName')

		assert_equal 1, config.endpoints.length
		assert_equal 'endpoint', config.endpoints['msg']
		
	end

	def test_loadMessageEndpointMappings_single_with_seperator
		config = Test_EndpointMapping.new

		config.setValue( 'MESSAGE_ENDPOINT_MAPPINGS', 'msg:endpoint;')
		config.Configure('localQueueName')

		assert_equal 1, config.endpoints.length
		assert_equal 'endpoint', config.endpoints['msg']
		
	end

	def test_loadMessageEndpointMappings_two
		config = Test_EndpointMapping.new

		config.setValue( 'MESSAGE_ENDPOINT_MAPPINGS', 'msg1:endpoint1;msg2:endpoint2')
		config.Configure('localQueueName')

		assert_equal 2, config.endpoints.length
		assert_equal 'endpoint1', config.endpoints['msg1']
		assert_equal 'endpoint2', config.endpoints['msg2']
		
	end

end
