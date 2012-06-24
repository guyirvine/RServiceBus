#RedisInjection

##What
An example of configuring a resource at the environment level, and having the rservicebus host inject it into a message handler

##How
make sure beanstalk is running
make sure redis is running

then

run ./run in a terminal

in another terminal, run
  ruby Client.rb
