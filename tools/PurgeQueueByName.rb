require "amqp"


if ARGV.length != 1 then
	abort( "Usage: PurgeQueueByName <queue name>" )
end
queueName = ARGV[0]

require "beanstalk-client"

if ARGV.length == 1 then
	queueName = ARGV[0]
	index = 1
else
	abort( "Usage: PurgeQueueByName <queue name>" )
end


beanstalk = Beanstalk::Pool.new(['localhost:11300'])
begin
	beanstalk.watch(queueName)
	loop do
		job = beanstalk.reserve 1
		job.delete
	end
rescue Exception => e
	if e.message == "TIMED_OUT" then
	else
		raise
	end
end
