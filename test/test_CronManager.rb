require 'test/unit'
require './lib/rservicebus/CronManager.rb'
require './Mock/Host.rb'

class Test_CronManager<RServiceBus::CronManager
	attr_accessor :list

end

class CronManagerTest < Test::Unit::TestCase

	def test_MultipleCronEntries
		ENV['RSBCRON'] = "1 * * * * Task 1;* 3 * * * Task 2"
		cron = Test_CronManager.new( RServiceBus::Mock_Host.new )

		assert_equal 2, cron.list.length
		assert_equal "Task 1", cron.list[0]['name']
		assert_equal "1 * * * *", cron.list[0]['v']
		assert_equal "Task 2", cron.list[1]['name']
	end

        def test_MultipleCronEntriesAndASingle
                ENV['RSBCRON_Task3'] = "4 * * * *"
                ENV['RSBCRON'] = "1 * * * * Task 1;* 3 * * * Task 2"
                cron = Test_CronManager.new( RServiceBus::Mock_Host.new )

                assert_equal 3, cron.list.length
                assert_equal "Task 1", cron.list[0]['name']
                assert_equal "1 * * * *", cron.list[0]['v']
                assert_equal "Task 2", cron.list[1]['name']
                assert_equal "Task3", cron.list[2]['name']
        end


end
