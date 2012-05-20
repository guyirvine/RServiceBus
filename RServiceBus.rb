require 'rubygems'


puts "Load Message Handlers"


handlerList = {};
Dir["MessageHandler/*.rb"].each do |filePath|
	requirePath = "./" + filePath.sub( ".rb", "")
	fileName = filePath.sub( "MessageHandler/", "")
	messageName = fileName.sub( ".rb", "" )
	handlerName = "MessageHandler_" + messageName
	puts filePath + ":" + fileName + ":" + messageName + ":" + handlerName


	require requirePath
	handlerList[messageName] = Object.const_get(handlerName).new();
	puts "Loaded Handler for: " + messageName
end


#require "./Transport/ZeroMq"
#transport = Transport_ZeroMq.new()
require "./Transport/RabbitMq"
transport = Transport_RabbitMq.new(handlerList, "error")
transport.Run()
