require './RServiceBus'
require './Contract'


if ARGV.length > 1 then
	abort('Usage: RServiceBus [config file name]')
end

configFilePath = ARGV.length == 0 ? nil : ARGV[0]

Bus = RServiceBus::Host.new(configFilePath)
	.loadHandlers()
	.loadSubscriptions()
	.sendSubscriptions()

1.upto(1) do |request_nbr|
	Bus.Publish( HelloWorldEvent.new( "Hello World: " + request_nbr.to_s ) )
end
