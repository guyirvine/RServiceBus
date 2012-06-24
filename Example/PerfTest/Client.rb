require "rservicebus"
require "./Contract"

agent = RServiceBus::Agent.new()

1.upto(10000) do |request_nbr|
	agent.sendMsg(PerfTest.new( "Hello World! " + request_nbr.to_s ), "PerfTest")
end
