
class MessageHandler_HelloWorld

	attr_accessor :Bus, :DataDir, :ScpUpload

	def Handle( msg )
		filePath = "#{@DataDir.path}/data.txt"

		RServiceBus.rlog "Writing to file: #{filePath}"

		IO.write( filePath, 'File Content')

		RServiceBus.rlog "Scp file, #{filePath}"
	
		@ScpUpload.upload( filePath )
	end
end
