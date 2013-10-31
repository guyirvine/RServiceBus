require 'test/unit'
require './lib/rservicebus/CircuitBreaker.rb'
require './lib/rservicebus/helper_functions.rb'
require './Mock/Host.rb'


class Test_CircuitBreaker<RServiceBus::CircuitBreaker
    #@maxNumberOfFailures = RServiceBus.getValue( "RSBCB_MAX", 5 )
    #@secondsToBreak = RServiceBus.getValue( "RSBCB_SECONDS_TO_BREAK", 60 ).to_i
    #@secondsToReset = RServiceBus.getValue( "RSBCB_SECONDS_TO_RESET", 60 ).to_i
    #@resetOnSuccess = RServiceBus.getValue( "RSBCB_RESET_ON_SUCCESS", false )

    attr_accessor :secondsToBreak, :secondsToReset, :timeToReset
end

class CircuitBreakerTest < Test::Unit::TestCase
    
    def setup
        ENV['TESTING'] = 'TRUE'
    end
    
	def test_OneSuccessNotBroken
        cb = Test_CircuitBreaker.new( RServiceBus::Mock_Host.new )
        
        cb.Success
        
		assert_equal true, cb.Live
	end
    
    def test_TwoSuccessNotBroken
        cb = Test_CircuitBreaker.new( RServiceBus::Mock_Host.new )
        
        cb.Success
        assert_equal true, cb.Live
        
        cb.Success
        assert_equal true, cb.Live
    end
    
    def test_FailureOneOfFiveNotBroken
        cb = Test_CircuitBreaker.new( RServiceBus::Mock_Host.new )
        
        cb.Failure
        assert_equal true, cb.Live
    end
    
    def test_FailureTwoOfFiveNotBroken
        cb = Test_CircuitBreaker.new( RServiceBus::Mock_Host.new )
        
        cb.Failure
        assert_equal true, cb.Live
        
        cb.Failure
        assert_equal true, cb.Live
    end
    
    def test_FailureFiveOfFiveBroken
        cb = Test_CircuitBreaker.new( RServiceBus::Mock_Host.new )
        
        cb.Failure
        assert_equal true, cb.Live
        
        cb.Failure
        assert_equal true, cb.Live
        
        cb.Failure
        assert_equal true, cb.Live
        
        cb.Failure
        assert_equal true, cb.Live
        
        cb.Failure
        assert_equal false, cb.Live
    end
    
    def test_FailureFiveOfFiveOutsideWindowNotBroken
        cb = Test_CircuitBreaker.new( RServiceBus::Mock_Host.new )
        cb.secondsToBreak = 0.1

        cb.Failure
        assert_equal true, cb.Live
        
        cb.Failure
        assert_equal true, cb.Live
        
        cb.Failure
        assert_equal true, cb.Live
        
        cb.Failure
        assert_equal true, cb.Live

        sleep 0.2

        cb.Live
        cb.Failure
        assert_equal true, cb.Live
    end
    
    def test_FailureFiveOfFiveBrokenThenFailureBeforeReset
        cb = Test_CircuitBreaker.new( RServiceBus::Mock_Host.new )
        cb.secondsToReset = 0.1

        cb.Failure
        assert_equal true, cb.Live

        cb.Failure
        assert_equal true, cb.Live

        cb.Failure
        assert_equal true, cb.Live

        cb.Failure
        assert_equal true, cb.Live

        cb.Failure
        assert_equal false, cb.Live

        sleep 0.2

        exception_raised = false
        begin
            cb.Failure
            rescue RServiceBus::MessageArrivedWhileCricuitBroken=>e
            exception_raised = true
        end
        assert_equal true, exception_raised
    end
    
    def test_FailureFiveOfFiveBrokenThenReset
        cb = Test_CircuitBreaker.new( RServiceBus::Mock_Host.new )
        cb.secondsToReset = 0.1
        
        cb.Failure
        assert_equal true, cb.Live
        
        cb.Failure
        assert_equal true, cb.Live
        
        cb.Failure
        assert_equal true, cb.Live
        
        cb.Failure
        assert_equal true, cb.Live
        
        cb.Failure
        assert_equal false, cb.Live
        
        sleep 0.5
        
        assert_equal true, cb.Live
    end
    
end
