require "rservicebus"
require "./Contract"

agent = RServiceBus::Agent.new()

1.upto(1) do |request_nbr|
	agent.sendMsg(HelloWorld.new( "Hello World! " + request_nbr.to_s ), "MyPublisher", "helloResponse")
end
