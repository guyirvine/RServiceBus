module RServiceBus

#Given a directory, this class is responsible for finding
#	msgnames,
#	handlernames, and
#	loading handlers
class HandlerLoader

	attr_reader :handlerList

	@baseDir
	@filepath

	@requirePath
	@handlerName

	@messageName
	@handler

	@handlerList
    
    @listOfLoadedPaths

# Constructor
#
# @param [RServiceBus::Host] host instance
# @param [Hash] appResources As hash[k,v] where k is the name of a resource, and v is the resource
	def initialize( host, handlerManager )
        @host = host
        
		@handlerManager = handlerManager
        
        @listOfLoadedPaths = Hash.new
	end

# Cleans the given path to ensure it can be used for as a parameter for the require statement.
#
# @param [String] filePath the path to be cleaned
	def getRequirePath( filePath )
		if !filePath.start_with?( "/" ) then
			filePath = "./" + filePath
		end
		
		if File.exists?( filePath ) then
			return filePath.sub( ".rb", "")
		end		

		abort( "Filepath, " + filePath + ", given for MessageHandler require doesn't exist" );
	end

# Instantiate the handler named in handlerName from the file name in filePath
# Exceptions will be raised if encountered when loading handlers. This is a load time activity, 
# so handlers should load correctly. As much information as possible is returned
# to enable the handler to be fixed, or configuration corrected.
#
# @param [String] handlerName name of the handler to instantiate
# @param [String] filePath the path to the file to be loaded
# @return [RServiceBus::Handler] the loader
	def loadHandlerFromFile( handlerName, filePath )
		requirePath = self.getRequirePath( filePath )

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
	
# Wrapper function
#
# @param [String] filePath
# @param [String] handlerName
# @returns [RServiceBus::Handler] handler
	def loadHandler(msgName, filePath, handlerName)
        if @listOfLoadedPaths.has_key?( filePath ) then
            RServiceBus.log "Not reloading, #{filePath}"
            return
        end

		begin
			RServiceBus.rlog "filePath: " + filePath
			RServiceBus.rlog "handlerName: " + handlerName

			handler = self.loadHandlerFromFile( handlerName, filePath )
			RServiceBus.log "Loaded Handler: " + handlerName

            @handlerManager.addHandler( msgName, handler )
            
            @listOfLoadedPaths[filePath] = 1
		rescue Exception => e
			puts "Exception loading handler from file: " + filePath
			puts e.message
			puts e.backtrace[0]

			abort()
		end

	end

#This method is overloaded for unit tests
#
# @param [String] path directory to check
# @return [Array] a list of paths to files found in the given path
	def getListOfFilesForDir( path )
        list = Dir[path + "/*"];
        RServiceBus.rlog "HandlerLoader.getListOfFilesForDir. path: #{path}, list: #{list}"
        
        return list
	end

#Multiple handlers for the same msg can be placed inside a top level directory.
#The msg name is than taken from the directory, and the handlers from the files inside that
#directory
#
# @param [String] msgName name of message
# @param [String] baseDir directory to check for handlers of the given msgName
	def loadHandlersFromSecondLevelPath(msgName, baseDir)
		self.getListOfFilesForDir(baseDir).each do |filePath|
			if !filePath.end_with?( "." ) then
				extName = File.extname( filePath )
				if !File.directory?( filePath ) &&
						extName == ".rb" then

					fileName = File.basename( filePath ).sub( ".rb", "" )
					handlerName = "MessageHandler_#{msgName}_#{fileName}"

					self.loadHandler( msgName, filePath, handlerName )
				end
			end
		end

		return self
	end


#Extract the top level dir or file name as it is the msg name
#
# @param [String] filePath path to check - this can be a directory or file
	def getMsgName( filePath )
		baseName = File.basename( filePath )
		extName = File.extname( baseName )
		fileName = baseName.sub( extName, "" )

		msgName = fileName
		
		return msgName
	end

#Load top level handlers from the given directory
#
# @param [String] baseDir directory to check - should not have trailing slash
	def loadHandlersFromTopLevelPath(baseDir)
        RServiceBus.rlog "HandlerLoader.loadHandlersFromTopLevelPath. baseDir: #{baseDir}"
		self.getListOfFilesForDir(baseDir).each do |filePath|
			if !filePath.end_with?( "." ) then

				msgName = self.getMsgName( filePath )
				if File.directory?( filePath ) then
					self.loadHandlersFromSecondLevelPath( msgName, filePath )
				else
					handlerName = "MessageHandler_#{msgName}"
					self.loadHandler( msgName, filePath, handlerName )
				end
			end
		end

		return self
	end

#Entry point for loading handlers
#
# @param [String] baseDir directory to check - should not have trailing slash
	def loadHandlersFromPath(baseDir)
		self.loadHandlersFromTopLevelPath(baseDir)

		return self
	end

end

end