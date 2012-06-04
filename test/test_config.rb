require 'test/unit'
require 'rservicebus'


class ConfigTest < Test::Unit::TestCase
  def getConfigString
  	buffer = [
"host: ",
"  appName: HelloWorld ",
"  errorQueueName: error ",
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

end
