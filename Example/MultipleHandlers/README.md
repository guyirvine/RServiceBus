#RServiceBus

A Ruby implementation of NServiceBus

Where I started this project to increase my knowledge of NServiceBus, it is now
proving to be a workable framework.


##Principles
	*Why are you doing it and what can go wrong
	*Dont solve infrastructure problems with software
		*Infrastructure in this case refers to anything not specific to the application domain

##Points of view in the framework
	* Bus
	* Handler
	* Client

#Platform
	* Messages
	* MessageHandler
	* MessageHandling
	* Queues
	* Transport
	* Transactions

##Message
	* Yaml
	* Unique Message ID's

##Queues
	* Durable
	* Store & Forward
	* Queues specified by config, determined by message type

##Transport
	* RabbitMQ

##MessageHandler
	* Name by convention - Handler name matchs filename
	* Handlers are dynamically loaded
	* If a handler fails to load, the service wont start - infrastructure problem

##MessageHandling
	* Transactions are good, use them
	* Given transactions, the first to do on error is retry
 	* Once we've used up retry, put the message on an error queue to process later - it's a logic problem	
	
