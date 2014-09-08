$:.unshift './../../lib'

require 'rservicebus'
require 'rservicebus/Agent'
require './Contract'

ENV['RSBMQ'] = 'beanstalk://localhost'
agent = RServiceBus::Agent.new

1.upto(10000) do |request_nbr|
	agent.sendMsg(PerfTest.new( 'Hello World! ' + request_nbr.to_s ), 'PerfTest')
end
