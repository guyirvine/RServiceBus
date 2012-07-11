#RServiceBus

A Ruby interpretation of NServiceBus

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
	* beanstalk

##MessageHandler
	* Name by convention - Handler name matchs filename
	* Single handler for message is in top level file
	* Multiple handlers for message are in files under top level directory
	* Handlers are dynamically loaded
	* If a handler fails to load, the service wont start - infrastructure problem

##MessageHandling
	* Transactions are good, use them
	* Given transactions, the first thing to do on error is retry
 	* Once we've used up retry, put the message on an error queue to process later - it's a logic problem	
