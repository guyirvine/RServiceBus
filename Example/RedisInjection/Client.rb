$:.unshift './../../lib'

require "redis"
require "rservicebus"

redis = Redis.new
require "rservicebus/Agent"
require "./Contract"

agent = RServiceBus::Agent.new.getAgent( URI.parse( "beanstalk://localhost" ) )

1.upto(2) do |request_nbr|
	redis.set "key." + request_nbr.to_s, "BigBangTheory." + request_nbr.to_s
	agent.sendMsg(HelloWorld.new( "key." + request_nbr.to_s ), "HelloWorld", "helloResponse")
end

msg = agent.checkForReply( "helloResponse"  )
puts msg
msg = agent.checkForReply( "helloResponse"  )
puts msg


