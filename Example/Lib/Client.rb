$:.unshift './../../lib'
require "rservicebus"
require "rservicebus/Agent"
require "./Contract"

agent = RServiceBus::Agent.new.getAgent( URI.parse( "beanstalk://localhost" ) )

agent.sendMsg(HelloWorld.new( "Hello World!" ), "HelloWorld", "helloResponse")

msg = agent.checkForReply( "helloResponse"  )
puts msg


