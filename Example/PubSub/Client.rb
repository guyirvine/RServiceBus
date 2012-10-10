$:.unshift './../../lib'

require "rservicebus"
require "./Contract"

agent = RServiceBus::Agent_Beanstalk.new()

agent.sendMsg(HelloWorld.new( "Hello World! " ), "MyPublisher", "helloResponse")
