module RServiceBus

class HandlerLoader

	attr_reader :messageName, :handler

	@host

	@baseDir
	@filepath

	@requirePath
	@handlerName

	@messageName
	@handler

	def initialize( baseDir, filePath, host )
		@host = host

		@baseDir = baseDir
		@filePath = filePath
	end

	def getMessageName( baseDir, fileName )
		name = fileName.sub( baseDir + "/", "" )
		if name.count( "/" ) == 0 then
			return name.match( /(.+)\./ )[1]
		end

		if name.count( "/" ) == 1 then
			return name.match( /\/(.+)\./ )[1]
		end

		puts "Filepath, " + fileName + ", not in the expected format."
		puts "Expected format either,"
		puts "MessageHandler/Hello.rb, or"
		puts "MessageHandler/Hello/One.rb, or"
		abort();
	end

	def getRequirePath( filePath )
		if File.exists?( filePath ) then
			return filePath.sub( ".rb", "")
		end		
		
		if File.exists?( "./" + filePath ) then
			return "./" + filePath.sub( ".rb", "")
		end

		abort( "Filepath, " + filePath + ", given for MessageHandler require doesn't exist" );
	end

	def parseFilepath
		@requirePath = self.getRequirePath( @filePath )
		@messageName = self.getMessageName( @baseDir, @filePath )
		@handlerName = @filePath.sub( ".rb", "").sub( @baseDir, "MessageHandler" ).gsub( "/", "_" )

		puts @handlerName
		puts @filePath + ":" + @messageName + ":" + @handlerName
	end

	def loadHandlerFromFile
		require @requirePath
		begin
			@handler = Object.const_get(@handlerName).new();
		rescue Exception => e
			puts "Expected class name: " + @handlerName + ", not found after require: " +  @requirePath
			puts "**** Check in " + @filePath + " that the class is named : " + @handlerName
			puts "( In case its not that )"
			raise e
		end
	end
	
	def setBusAttributeIfRequested
		if defined?( @handler.Bus ) then
			@handler.Bus = @host
			puts "Bus attribute set for: " + @handlerName
		end
	end

	def loadHandler()
		begin
			self.parseFilepath
			self.loadHandlerFromFile
			self.setBusAttributeIfRequested
			puts "Loaded Handler: " + @handlerName + ", for, " + @messageName
		rescue Exception => e
			puts "Exception loading handler from file: " + @filePath
			puts e.message
			puts e.backtrace[0]

			abort()
		end

	end

end

end