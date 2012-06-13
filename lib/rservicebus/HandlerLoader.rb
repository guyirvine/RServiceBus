module RServiceBus

class HandlerLoader

	attr_reader :messageName, :handler

	@host
	@appResources

	@baseDir
	@filepath

	@requirePath
	@handlerName

	@messageName
	@handler

	def initialize( host, appResources )
		@host = host
		@appResources = appResources
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
		if !filePath.start_with?( "/" ) then
			filePath = "./" + filePath
		end
		
		if File.exists?( filePath ) then
			return filePath.sub( ".rb", "")
		end		

		abort( "Filepath, " + filePath + ", given for MessageHandler require doesn't exist" );
	end

	def getHandlerName( baseDir, filePath )
		handlerName = filePath.sub( ".rb", "").sub( baseDir, "MessageHandler" ).gsub( "/", "_" )
		return handlerName
	end

	def loadHandlerFromFile( requirePath, handlerName, filePath )
		require requirePath
		begin
			handler = Object.const_get(handlerName).new();
		rescue Exception => e
			puts "Expected class name: " + handlerName + ", not found after require: " +  requirePath
			puts "**** Check in " + filePath + " that the class is named : " + handlerName
			puts "( In case its not that )"
			raise e
		end
		
		return handler
	end
	
	def setBusAttributeIfRequested( handler, handlerName )
		if defined?( handler.Bus ) then
			handler.Bus = @host
			@host.log "Bus attribute set for: " + handlerName
		end
	end

	def setAppResources( handler, handlerName, appResources )
		@host.log "Checking app resources for: #{handlerName}", true
		appResources.each do |k,v|
			if handler.class.method_defined?( k ) then 
				handler.instance_variable_set( "@#{k}", v.getResource() )
				@host.log "App resource attribute, #{k}, set for: " + handlerName
			end
		end
	end

	def loadHandler(baseDir, filePath)
		begin
			requirePath = self.getRequirePath( filePath )
			messageName = self.getMessageName( baseDir, filePath )
			handlerName = self.getHandlerName( baseDir, filePath )

			@host.log "filePath: " + filePath, true
			@host.log "requirePath: " + requirePath, true
			@host.log "messageName: " + messageName, true
			@host.log "handlerName: " + handlerName, true

			handler = self.loadHandlerFromFile( requirePath, handlerName, filePath )
			self.setBusAttributeIfRequested( handler, handlerName )
			self.setAppResources( handler, handlerName, @appResources )
			@host.log "Loaded Handler: " + handlerName + ", for, " + messageName

			return messageName, handler
		rescue Exception => e
			puts "Exception loading handler from file: " + filePath
			puts e.message
			puts e.backtrace[0]

			abort()
		end

	end

end

end