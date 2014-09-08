require 'test/unit'
require './lib/rservicebus/Monitor/CsvDir.rb'


class Test_Monitor_CsvDir<RServiceBus::Monitor_CsvDir
    
    def setCols( cols )
        @QueryStringParts = Hash['cols', [cols]]
    end
    
end

class ConfigTest < Test::Unit::TestCase
    
    def test_CheckNumberOfColumnsWithOneRowCorrectNumberOfColumns
        monitor = Test_Monitor_CsvDir.new
        monitor.setCols( 2 )
        
        monitor.ProcessContent('1, 2')
        
    end
    
    def test_CheckNumberOfColumnsOneRowIncorrectNumberOfColumns
        monitor = Test_Monitor_CsvDir.new
        monitor.setCols( 2 )
        
        error_raised = false
        begin
            monitor.ProcessContent('1, 2, 3')
            rescue
            error_raised = true
        end
        
        assert_equal true, error_raised
        
    end
    
    def test_CheckNumberOfColumnsMultipleRowsCorrectNumberOfColumns
        monitor = Test_Monitor_CsvDir.new
        monitor.setCols( 2 )
        
        monitor.ProcessContent( "1, 2\n3, 4\n5, 6" )
        
    end
    
    def test_CheckNumberOfColumnsMultipleRowsIncorrectNumberOfColumns
        monitor = Test_Monitor_CsvDir.new
        monitor.setCols( 2 )
        
        error_raised = false
        begin
            monitor.ProcessContent( "1, 2\n3, 4, 8\n5, 6" )
            rescue
            error_raised = true
        end
        
        assert_equal true, error_raised
    end
    
    def test_CheckNumberOfColumnsMultipleRows
        monitor = Test_Monitor_CsvDir.new
        monitor.setCols( 2 )
        
            monitor.ProcessContent( "1, 2\n3, 4\n5, 6\n" )
    end
end
