$:.unshift './../../lib'

require "rservicebus"
require "./Contract"

agent = RServiceBus::Agent_Beanstalk.new()

agent.sendMsg(HelloWorld.new( "Hello World!" ), "HelloWorldMultiple", "helloWorldMultipleResponse")

puts agent.checkForReply( "helloWorldMultipleResponse"  )
puts agent.checkForReply( "helloWorldMultipleResponse"  )
