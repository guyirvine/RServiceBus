require "rservicebus"
require "./Contract"
require "./MessageHandler/PerfTest"

agent = RServiceBus::Agent.new()
handler = MessageHandler_PerfTest.new

1.upto(10000) do |request_nbr|
	agent.sendMsg(PerfTest.new( "Hello World! " + request_nbr.to_s ), "PerfTest")
	#handler.Handle( PerfTest.new( "Hello World! " + request_nbr.to_s ) )
end
