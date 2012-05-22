require 'rubygems'


puts "Load Message Handlers"


#require "./Transport/ZeroMq"
#transport = Transport_ZeroMq.new()
require "./Transport/RabbitMq"
transport = Transport_RabbitMq.new("error")


handlerList = {};
Dir["MessageHandler/*.rb"].each do |filePath|
	requirePath = "./" + filePath.sub( ".rb", "")
	fileName = filePath.sub( "MessageHandler/", "")
	messageName = fileName.sub( ".rb", "" )
	handlerName = "MessageHandler_" + messageName
	puts filePath + ":" + fileName + ":" + messageName + ":" + handlerName


	require requirePath
	handler = Object.const_get(handlerName).new();
	if defined?( handler.Bus ) then
		puts "Writing"
		handler.Bus = transport
	end if
	handlerList[messageName] = handler;

	puts "Loaded Handler for: " + messageName
end

transport.handlerList = handlerList
transport.Run()
