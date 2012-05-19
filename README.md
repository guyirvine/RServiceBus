#RServiceBus

To increase my knowledge of the the thought process behind NServiceBus.


##Who's involved
* Three Actors
	* Bus
	* Handler
	* Client

#Platform
	* Messages
	* MessageHandler
	* Transport
	* Queues
	* Transactions

##Message
	* XML
	* Unique Message ID's

##Transport
	* ZeroMQ
	* RabbitMQ

##Queues
	* Storage
		* For durable messages
		* Redis ?
	* RabbitMQ
	* Queues specified by config, determined by message type

##MessageHandler
	* Handlers by convention
	* Handlers are dynamically loaded
