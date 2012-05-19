require 'rubygems'
require 'ffi-rzmq'


class Transport_ZeroMq

	def Listen( handlerList )
	
puts "Wait for Msgs"

context = ZMQ::Context.new(1)

#Socket to talk to clients
responder = context.socket(ZMQ::REP)
responder.bind("tcp://*:5555")

while(true) do
	#Wait for next request from client
	msg = ''
    rc = responder.recv_string(msg)
    responder.send_string("World")
   handler = handlerList[msg]
    
    if handler == nil then
	    puts "Received request: [#{msg}]"
    else
    	puts "Handler Found"
    	handler.Handle( msg )
	end
end

	end
end
