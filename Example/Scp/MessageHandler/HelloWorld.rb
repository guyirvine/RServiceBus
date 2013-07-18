
class MessageHandler_HelloWorld

	attr_accessor :Bus, :DataDir, :ScpUpload

	def Handle( msg )
		filePath = "#{@DataDir.path}/data.txt"

		@Bus.log "Writing to file: #{filePath}", true

		IO.write( filePath, "File Content" )

		@Bus.log "Scp file, #{filePath}", true
	
		@ScpUpload.upload( filePath )
	end
end
