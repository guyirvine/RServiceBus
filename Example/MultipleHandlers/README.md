#Multiple Handlers

##What
Two message handlers have been written, and will run in a single rservicebus host

##How
make sure beanstalk is running, then

In the server terminal, type
  ./run

In the client terminal, type
  ruby Client.rb


In the server terminal, you should see
MessageHandler_HelloWorld_One: HelloWorld
MessageHandler_HelloWorld_Two: HelloWorld


In the client terminal, you should see
Reply from MessageHandler_HelloWorld_One
Reply from MessageHandler_HelloWorld_Two

