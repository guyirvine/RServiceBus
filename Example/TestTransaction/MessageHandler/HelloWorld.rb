require './Contract.rb'

#Need to create a postgresql db called rservicebus_test, and a table called table_tbl

class MessageHandler_HelloWorld
    
	attr_accessor :Bus, :Test
    
    
	def Handle( msg )
        
        @Test.execute( 'UPDATE table1 SET field1 = 2', [] );
        
        @Bus.Send( TestMsg.new )

        raise "A user based exception" if msg.id == 1
	end
end
