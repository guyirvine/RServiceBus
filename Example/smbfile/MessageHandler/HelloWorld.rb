
class MessageHandler_HelloWorld

	attr_accessor :Bus, :TestSmbFile

	def Handle( msg )
		puts 'TestSmbFile: '
		size = @TestSmbFile.stat.size
		buffer = @TestSmbFile.read( size )
		puts "buffer: #{buffer}"
	end
end
