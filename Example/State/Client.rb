$:.unshift './../../lib'
require "rservicebus"
require "./Contract"

RServiceBus.SendMsg( HelloWorld.new( "1" ) )

