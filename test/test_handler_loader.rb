require 'test/unit'
require './lib/rservicebus/HandlerLoader.rb'


class HandlerLoaderTest < Test::Unit::TestCase

	def test_getMessageName_for_single_handler
		baseDir="/one/two/MessageHandler"
		fileName="/one/two/MessageHandler/One.rb"
		msgName = RServiceBus::HandlerLoader.new(nil, nil, nil ).getMessageName( baseDir, fileName )

		assert_equal "One", msgName
	end

	def test_getMessageName_for_multiple_handler
		baseDir="/one/two/MessageHandler"

		fileName="/one/two/MessageHandler/One/A.rb"
		msgName = RServiceBus::HandlerLoader.new(nil, nil, nil ).getMessageName( baseDir, fileName )
		assert_equal "A", msgName

		fileName="/one/two/MessageHandler/One/B.rb"
		msgName = RServiceBus::HandlerLoader.new(nil, nil, nil ).getMessageName( baseDir, fileName )
		assert_equal "B", msgName
	end


end
