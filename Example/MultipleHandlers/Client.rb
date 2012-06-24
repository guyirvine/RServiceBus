require "rservicebus"
require "./Contract"

agent = RServiceBus::Agent.new()

agent.sendMsg(HelloWorld.new( "Hello World!" ), "HelloWorldMultiple", "helloWorldMultipleResponse")

puts agent.checkForReply( "helloWorldMultipleResponse"  )
puts agent.checkForReply( "helloWorldMultipleResponse"  )
