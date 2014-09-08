$:.unshift './../../lib'

require 'rservicebus'
require 'rservicebus/Agent'
require './Contract'

ENV['RSBMQ'] = 'beanstalk://localhost'
agent = RServiceBus::Agent.new

agent.sendMsg(HelloWorld.new('Hello World! '), 'MyPublisher', 'helloResponse')
