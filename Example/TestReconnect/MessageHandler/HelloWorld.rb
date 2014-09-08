require './Contract.rb'

#Need to create a postgresql db called rservicebus_test, and a table called table_tbl

class MessageHandler_HelloWorld
    
	attr_accessor :Bus, :Bcs
    
    
	def Handle( msg )
        @counter = 0 if @counter.nil?
        @counter = @counter + 1
        raise 'Manually generated error for testng' if @counter == 1
        
        count = @Bcs.queryForValue( 'SELECT count(*) FROM table_tbl;', [] );
        
		puts "Handling Hello World: #{msg.name}. Count: #{count}"
        
        @counter = 0
	end
end
