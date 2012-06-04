module RServiceBus

class HandlerLoader

	attr_reader :messageName, :handler

	@host

	@logger
	@filepath

	@requirePath
	@handlerName

	@messageName
	@handler

	def initialize( logger, filePath, host )
		@host = host

		@logger = logger
		@filePath = filePath
	end

	def getMessageName( fileName )
		if fileName.count( "/" ) == 1 then
			return fileName.match( /\/(.+)\./ )[1]
		end
				
		if fileName.count( "/" ) == 2 then
			return fileName.match( /\/(.+)\// )[1]
		end
		
		
		puts "Filepath, " + fileName + ", not in the expected format."
		puts "Expected format either,"
		puts "MessageHandler/Hello.rb, or"
		puts "MessageHandler/Hello/One.rb, or"
		abort();
	end

	def parseFilepath
		@requirePath = "./" + @filePath.sub( ".rb", "")
		@messageName = self.getMessageName( @filePath )
		@handlerName = @filePath.sub( ".rb", "").gsub( "/", "_" )

		@logger.debug @handlerName
		@logger.debug @filePath + ":" + @messageName + ":" + @handlerName
	end

	def loadHandlerFromFile
		require @requirePath
		begin
			@handler = Object.const_get(@handlerName).new();
		rescue Exception => e
			@logger.fatal "Expected class name: " + @handlerName + ", not found after require: " +  @requirePath
			@logger.fatal "**** Check in " + @filePath + " that the class is named : " + @handlerName
			@logger.fatal "( In case its not that )"
			raise e
		end
	end
	
	def setBusAttributeIfRequested
		if defined?( @handler.Bus ) then
			@handler.Bus = @host
			@logger.debug "Bus attribute set for: " + @handlerName
		end
	end

	def loadHandler()
		begin
			self.parseFilepath
			self.loadHandlerFromFile
			self.setBusAttributeIfRequested
			@logger.info "Loaded Handler: " + @handlerName
		rescue Exception => e
			@logger.fatal "Exception loading handler from file: " + @filePath
			@logger.fatal e.message
			@logger.fatal e.backtrace[0]

			abort()
		end

	end

end

end