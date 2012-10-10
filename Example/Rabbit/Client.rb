$:.unshift './../../lib'
require "rservicebus"
require "./Contract"

agent = RServiceBus::Agent_Bunny.new()

1.upto(2) do |request_nbr|
	agent.sendMsg(HelloWorld.new( "Hello World! " + request_nbr.to_s ), "HelloWorld", "helloResponse")
end

sleep( 0.5 )
msg = agent.checkForReply( "helloResponse"  )
puts msg
sleep( 0.5 )
msg = agent.checkForReply( "helloResponse"  )
puts msg


