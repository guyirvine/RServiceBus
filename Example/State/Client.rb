$:.unshift './../../lib'
require "rservicebus"
require "rservicebus/Agent"
require "./Contract"

agent = RServiceBus::Agent.new.getAgent( URI.parse( "beanstalk://localhost" ) )

1.upto(2) do |request_nbr|
	agent.sendMsg(HelloWorld.new, "State", "stateResponse")
end



