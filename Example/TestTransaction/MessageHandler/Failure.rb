require "./Contract.rb"

#Need to create a postgresql db called rservicebus_test, and a table called table_tbl

class MessageHandler_Failure
    
	attr_accessor :Bus
    
    
	def Handle( msg )
        @Bus.Send( HelloWorld.new( 1 ) )
	end
end
