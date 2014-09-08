$:.unshift './../../lib'
require 'rservicebus'
require 'rservicebus/Agent'
require './Contract'

agent = RServiceBus::Agent.new.getAgent( URI.parse('beanstalk://localhost') )

agent.sendMsg(RServiceBus::Message_VerboseOutputOn.new, 'HelloWorld', 'helloResponse')

