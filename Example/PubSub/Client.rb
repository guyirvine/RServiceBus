require "rservicebus"
require "./Contract"

agent = RServiceBus::Agent.new()

agent.sendMsg(HelloWorld.new( "Hello World! " ), "MyPublisher", "helloResponse")
