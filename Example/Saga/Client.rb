$:.unshift './../../lib'
require 'rservicebus'
require 'rservicebus/Agent'
require './Contract'

ENV['RSBMQ'] = 'beanstalk://localhost'
agent = RServiceBus::Agent.new

agent.sendMsg(Msg1.new('1'), 'Saga', 'helloResponse')


