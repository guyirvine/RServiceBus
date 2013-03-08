
class MessageHandler_HelloWorld

	attr_accessor :Bus, :OutputDir
    
    @OutputDir

    
	def Handle( msg )
        IO.write( @OutputDir.path + "/output.txt", msg.payload )
	end
end
