require 'test/unit'
require './lib/rservicebus/Config.rb'


class Test_Config<RServiceBus::Config

	attr_reader :requireList

	def initialize
		@valueList = Hash.new
		@requireList = Array.new
	end

	def getValue( name, default=nil )
		value = ( @valueList[name].nil? || @valueList[name] == '') ? default : @valueList[name];
		return value
	end

	def setValue( name, value )
		@valueList[name] = value
	end

	def log(string)
	end

	def performRequire( path )
		@requireList << path
	end

	def ensureContractFileExists( path )
	end

end

class ConfigTest < Test::Unit::TestCase

	def test_loadHandlerPathList_nil
		config = Test_Config.new

		config.loadHandlerPathList

		assert_equal 1, config.handlerPathList.length
		assert_equal './MessageHandler', config.handlerPathList[0]
	end

	def test_loadHandlerPathList_empty
		config = Test_Config.new

		config.setValue( 'MSGHANDLERPATH', '')
		config.loadHandlerPathList

		assert_equal 1, config.handlerPathList.length
		assert_equal './MessageHandler', config.handlerPathList[0]
	end

	def test_loadHandlerPathList_single
		config = Test_Config.new

		config.setValue( 'MSGHANDLERPATH', '/path')
		config.loadHandlerPathList

		assert_equal 1, config.handlerPathList.length
		assert_equal '/path', config.handlerPathList[0]
		
	end

	def test_loadHandlerPathList_single_with_seperator
		config = Test_Config.new

		config.setValue( 'MSGHANDLERPATH', '/path;')
		config.loadHandlerPathList

		assert_equal 1, config.handlerPathList.length
		assert_equal '/path', config.handlerPathList[0]

	end

	def test_loadHandlerPathList_two
		config = Test_Config.new

		config.setValue( 'MSGHANDLERPATH', '/path1;/path2')
		config.loadHandlerPathList

		assert_equal 2, config.handlerPathList.length
		assert_equal '/path1', config.handlerPathList[0]
		assert_equal '/path2', config.handlerPathList[1]
		
	end

	def test_loadHandlerPathList_two_with_trailing_slash
		config = Test_Config.new

		config.setValue( 'MSGHANDLERPATH', '/path1/;/path2/')
		config.loadHandlerPathList

		assert_equal 2, config.handlerPathList.length
		assert_equal '/path1', config.handlerPathList[0]
		assert_equal '/path2', config.handlerPathList[1]
		
	end

	def test_loadContracts_single
		config = Test_Config.new

		config.setValue( 'CONTRACTS', '/path')
		config.loadContracts

		assert_equal 1, config.contractList.length
		assert_equal '/path', config.contractList[0]
		
	end

	def test_loadContracts_single_with_seperator
		config = Test_Config.new

		config.setValue( 'CONTRACTS', '/path;')
		config.loadContracts

		assert_equal 1, config.contractList.length
		assert_equal '/path', config.contractList[0]

	end

	def test_loadContracts_two
		config = Test_Config.new

		config.setValue( 'CONTRACTS', '/path1;/path2')
		config.loadContracts

		assert_equal 2, config.contractList.length
		assert_equal '/path1', config.contractList[0]
		assert_equal '/path2', config.contractList[1]
		
	end

end
