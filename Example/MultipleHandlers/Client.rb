require "rservicebus"
require "./Contract"

agent = RServiceBus::Agent.new()

1.upto(2) do |request_nbr|
	agent.sendMsg(HelloWorld.new( "Hello World! " + request_nbr.to_s ), "HelloWorldMultiple", "helloResponse")
end
