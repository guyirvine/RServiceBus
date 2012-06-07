require "beanstalk-client"

if ARGV.length == 1 then
	queueName = ARGV[0]
	index = 1
elsif ARGV.length == 2 then
	queueName = ARGV[0]
	index = ARGV[1].to_i
else
	abort( "Usage: PeekAtQueue <queue name> [index]" )
end


beanstalk = Beanstalk::Pool.new(['localhost:11300'])
jobList = Array.new
begin
	beanstalk.watch(queueName)
	1.upto(index) do
		job = beanstalk.reserve 1
		jobList << job
	end
	puts jobList.last.body
rescue Exception => e
	if e.message == "TIMED_OUT" then
		puts "Timeout"
	else
		raise
	end
end

jobList.each do |job|
	job.release
end

