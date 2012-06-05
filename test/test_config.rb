require 'test/unit'
require 'rservicebus'


class ConfigTest < Test::Unit::TestCase

	HANDLER_PATH=3

  def getConfigString
  
  
  	buffer = [
"host: ",
"  appName: HelloWorld ",
"  errorQueueName: error ",
"  messageHandlerPath: CustomMessageHandler",
" ",
"logger: ",
"  level: INFO ",
"  stdout: false ",
"  fileName: false ",
"  fileFormat: \"[%l] %d :: %m\" ",
]

  end


	def test_standard
		buffer = self.getConfigString().join( "\n" )

		config = RServiceBus::ConfigFromYAMLObject
					.new( YAML.load(buffer) )
					.processConfig( RServiceBus::Host.new() )
		assert_equal "HelloWorld", config.appName
	end


	def test_defaulthandler_path
	  	config = self.getConfigString()
	  	config.delete_at( HANDLER_PATH )
	  	buffer = config.join( "\n" )

	  	config = RServiceBus::ConfigFromYAMLObject
  					.new( YAML.load(buffer) )
  					.processConfig( RServiceBus::Host.new() )
	    assert_equal 1, config.handlerPathList.length
	    assert_equal "MessageHandler", config.handlerPathList[0]
	end

	def test_singlehandler_path
	  	buffer = self.getConfigString().join( "\n" )

	  	config = RServiceBus::ConfigFromYAMLObject
  					.new( YAML.load(buffer) )
  					.processConfig( RServiceBus::Host.new() )
	    assert_equal 1, config.handlerPathList.length
	    assert_equal "CustomMessageHandler", config.handlerPathList[0]
	end

	def test_multiplehandler_path
	  	config = self.getConfigString()
	  	config[HANDLER_PATH] += ",AnotherPath"
	  	buffer = config.join( "\n" )

	  	config = RServiceBus::ConfigFromYAMLObject
  					.new( YAML.load(buffer) )
  					.processConfig( RServiceBus::Host.new() )
	    assert_equal 2, config.handlerPathList.length
	    assert_equal "CustomMessageHandler", config.handlerPathList[0]
	    assert_equal "AnotherPath", config.handlerPathList[1]
	end

	def test_multiplehandler_path_with_extra_chars
	  	config = self.getConfigString()
	  	config[HANDLER_PATH] += ", AnotherPath/Followed/ "
	  	buffer = config.join( "\n" )

	  	config = RServiceBus::ConfigFromYAMLObject
  					.new( YAML.load(buffer) )
  					.processConfig( RServiceBus::Host.new() )
	    assert_equal 2, config.handlerPathList.length
	    assert_equal "CustomMessageHandler", config.handlerPathList[0]
	    assert_equal "AnotherPath/Followed", config.handlerPathList[1]
	end
end
