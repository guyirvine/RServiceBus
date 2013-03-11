
class MessageHandler_HelloWorld

	attr_accessor :Bus, :OutputDir
    
    @OutputDir

    
	def Handle( msg )
        IO.write( @OutputDir.path + "/#{File.basename( msg.uri.path )}", msg.payload )
	end
end
