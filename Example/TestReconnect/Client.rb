$:.unshift './../../lib'

require 'redis'
require 'rservicebus'

redis = Redis.new
require 'rservicebus/Agent'
require './Contract'

ENV['RSBMQ'] = 'beanstalk://localhost'
agent = RServiceBus::Agent.new

request_nbr = 1
redis.set 'key.' + request_nbr.to_s, 'BigBangTheory.' + request_nbr.to_s
agent.sendMsg(HelloWorld.new( "key." + request_nbr.to_s ), "HelloWorld", "helloResponse")

