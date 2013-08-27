#Req

##What
Chaining MessageHandlers - Having once Handler passing a message to a second Hanlder.

A single client, using the agent to send a message

A single message handler, running inside rservicebus which receives 
the message and sends a message to a second Handler

The second handler acknowledges the receive by outputing to stdout

##How
make sure beanstalk is running, then

run the
  ./run

command in one terminal

in a second terminal, run
  ruby Client.rb


