module RServiceBus

#Given a directory, this class is responsible loading Sagas
class SagaLoader

	attr_reader :sagaList

    @listOfLoadedPaths

# Constructor
#
# @param [RServiceBus::Host] host instance
# @param [Hash] appResources As hash[k,v] where k is the name of a resource, and v is the resource
	def initialize( host, sagaManager )
        @host = host
        
		@sagaManager = sagaManager
        
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

		abort( "Filepath, " + filePath + ", given for Saga require doesn't exist" );
	end

# Instantiate the saga named in sagaName from the file name in filePath
# Exceptions will be raised if encountered when loading sagas. This is a load time activity,
# so sagas should load correctly. As much information as possible is returned
# to enable the saga to be fixed, or configuration corrected.
#
# @param [String] sagaName name of the saga to instantiate
# @param [String] filePath the path to the file to be loaded
# @return [RServiceBus::Saga] the loader
	def loadSagaFromFile( sagaName, filePath )
		requirePath = self.getRequirePath( filePath )

		require requirePath
		begin
			saga = Object.const_get(sagaName);
		rescue Exception => e
			puts "Expected class name: " + sagaName + ", not found after require: " +  requirePath
			puts "**** Check in " + filePath + " that the class is named : " + sagaName
			puts "( In case its not that )"
			raise e
		end

		return saga
	end
	
# Wrapper function
#
# @param [String] filePath
# @param [String] sagaName
# @returns [RServiceBus::Saga] saga
	def loadSaga(filePath, sagaName)
        if @listOfLoadedPaths.has_key?( filePath ) then
            RServiceBus.log "Not reloading, #{filePath}"
            return
        end

		begin
			RServiceBus.rlog "filePath: " + filePath
			RServiceBus.rlog "sagaName: " + sagaName

			saga = self.loadSagaFromFile( sagaName, filePath )
			RServiceBus.log "Loaded Saga: " + sagaName

            @sagaManager.RegisterSaga( saga )
	
            @listOfLoadedPaths[filePath] = 1
		rescue Exception => e
			puts "Exception loading saga from file: " + filePath
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

        RServiceBus.rlog "SagaLoader.getListOfFilesForDir. path: #{path}, list: #{list}"

        return list
	end

#Extract the top level dir or file name as it is the msg name
#
# @param [String] filePath path to check - this can be a directory or file
	def getSagaName( filePath )
		baseName = File.basename( filePath )
		extName = File.extname( baseName )
		
        sagaName = baseName.sub( extName, "" )
		
		return "Saga_#{sagaName}"
	end


#Entry point for loading Sagas
#
# @param [String] baseDir directory to check - should not have trailing slash
	def loadSagasFromPath(baseDir)
        RServiceBus.rlog "SagaLoader.loadSagasFromPath. baseDir: #{baseDir}"
        
		self.getListOfFilesForDir(baseDir).each do |filePath|
			if !filePath.end_with?( "." ) then
                
				sagaName = self.getSagaName( filePath )
                self.loadSaga( filePath, sagaName )
			end
		end
        
		return self
	end

end

end