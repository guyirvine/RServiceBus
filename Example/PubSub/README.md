#PubSub

##What
The quintessential pubsub example.


##How
make sure beanstalk is running
make sure redis is running

then

run ./run_sub1 in a terminal
run ./run_sub2 in a terminal
run ./run_pub in a terminal

in another terminal, run
  ruby Client.rb
