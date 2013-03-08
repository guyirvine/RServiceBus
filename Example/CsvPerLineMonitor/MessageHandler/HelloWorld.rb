
class MessageHandler_HelloWorld

	attr_accessor :Bus, :OutputDir
    
    @OutputDir

    
	def Handle( msg )
        @counter = 0 if @counter.nil?
        @counter = @counter + 1

        IO.write( @OutputDir.path + "/output.#{@counter}", msg.payload.to_s )
	end
end
