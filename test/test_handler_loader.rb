require 'test/unit'
require './lib/rservicebus/HandlerLoader.rb'
require './lib/rservicebus/Test/Bus.rb'

class TestHandlerLoader<RServiceBus::HandlerLoader
	
	def initialize
		@handlerList = Hash.new
		@fileList = Hash.new
		
		@host = RServiceBus::Test_Bus.new
	end

	def addListOfFilesInDir( path, list )
		@fileList[path] = list
	end

	def getListOfFilesForDir( path )
		return @fileList[path]
	end

	def loadAndConfigureHandler( filePath, handlerName )
		return handlerName;
	end
end


class HandlerLoaderTest < Test::Unit::TestCase

	def test_getMsgName_for_single_handler
		handlerLoader = TestHandlerLoader.new

		fileName="/one/two/MessageHandler/One.rb"
		msgName = handlerLoader.getMsgName( fileName )

		assert_equal "One", msgName
	end

	def test_getMsgName_for_multiple_handler
		handlerLoader = TestHandlerLoader.new

		filePath="/one/two/MessageHandler/One"
		msgName = handlerLoader.getMsgName( filePath )
		assert_equal "One", msgName

		fileName="/one/two/MessageHandler/One/"
		msgName = handlerLoader.getMsgName( filePath )
		assert_equal "One", msgName
	end


	def test_load_handler_for_single_handler
		handlerLoader = TestHandlerLoader.new

		#configure the test handler
		baseDir="/one/two/MessageHandler"
		filePath="/one/two/MessageHandler/One.rb"
		fileList=Array.new.push( filePath )
		handlerLoader.addListOfFilesInDir( baseDir, fileList )

		#load the handler
		handlerLoader.loadHandlersFromPath(baseDir)

		assert_equal 1, handlerLoader.handlerList.length
	end
	
	def test_load_two_handlers_two_msgs
		handlerLoader = TestHandlerLoader.new

		baseDir="/one/two/MessageHandler"
		fileList=Array.new
					.push( baseDir + "/One.rb" )
					.push( baseDir + "/Two.rb" )
		handlerLoader.addListOfFilesInDir( baseDir, fileList )

		handlerLoader.loadHandlersFromPath(baseDir)

		assert_equal 2, handlerLoader.handlerList.length
	end
	
	def test_load_multiple_handlers_single_msg
		handlerLoader = TestHandlerLoader.new

		baseDir="/one/two/MessageHandler"
		fileList=Array.new
			.push( baseDir + "/HelloWorld/One.rb" )
			.push( baseDir + "/HelloWorld/Two.rb" )
		handlerLoader.addListOfFilesInDir( baseDir, fileList )

		handlerLoader.loadHandlersFromPath(baseDir)

		assert_equal 2, handlerLoader.handlerList.length
	end

end
