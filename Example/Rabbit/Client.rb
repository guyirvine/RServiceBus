$:.unshift './../../lib'
require "rservicebus"
require "rservicebus/Agent"
require "./Contract"

agent = RServiceBus::Agent.new.getAgent( URI.parse( "bunny://localhost" ) )

1.upto(2) do |request_nbr|
	agent.sendMsg(HelloWorld.new( "Hello World! " + request_nbr.to_s ), "HelloWorld", "helloResponse")
end

sleep( 0.5 )
msg = agent.checkForReply( "helloResponse"  )
puts msg
sleep( 0.5 )
msg = agent.checkForReply( "helloResponse"  )
puts msg


