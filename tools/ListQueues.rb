require "beanstalk-client"

verbose = ARGV.length > 0 && ARGV[0] == "-v"

host = 'localhost:11300'
beanstalk = Beanstalk::Pool.new([host])

beanstalk.list_tubes[host].each do |name|
	tubeStats = beanstalk.stats_tube(name)
	puts name + "(" + tubeStats["current-jobs-ready"].to_s + ")"
	if verbose == true then
		puts tubeStats
	end
end
