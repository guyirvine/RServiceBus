#XmlMonitor

##What
An example of using the xml directory monitor to pull data in to the RServiceBus system

A single client, which adds data to the input directory

A single message handler, running inside rservicebus which receives 
the csv file as a message and write a reply to the output directory


##How
make sure beanstalk is running, then

run the
  ./run

command in one terminal

in a second terminal, run
  ruby Client.rb


