$:.unshift './../../lib'
require "rservicebus"
require "rservicebus/Agent"
require "./Contract"

ENV['MESSAGE_ENDPOINT_MAPPINGS']="HelloWorld:HelloWorld"
ENV['AUDIT_QUEUE_NAME']="ClientAudit"

1.upto(2) do |request_nbr|
	RServiceBus.sendMsg( HelloWorld.new( "Hello World! " + request_nbr.to_s ), "helloResponse")
end

msg = RServiceBus.checkForReply( "helloResponse"  )
puts msg
msg = RServiceBus.checkForReply( "helloResponse"  )
puts msg


