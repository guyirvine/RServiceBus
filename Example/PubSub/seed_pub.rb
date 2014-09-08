require 'redis'

redis = Redis.new

appName = 'MyPublisher'
redis.del appName + '.Subscriptions.HelloWorldEvent'
redis.sadd appName + '.Subscriptions.HelloWorldEvent', 'MySubscriber1'
redis.sadd appName + '.Subscriptions.HelloWorldEvent', 'MySubscriber2'

subscriptions = redis.keys appName + '.Subscriptions.*Event'

subscriptions.each do |subscriptionName|
	puts subscriptionName
	puts 'EventName: ' + subscriptionName.sub( appName + '.Subscriptions.', '')
	subscription = redis.smembers subscriptionName
	subscription.each do |subscriber|
		puts subscriber
	end
end
