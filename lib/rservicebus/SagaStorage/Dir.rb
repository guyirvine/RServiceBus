module RServiceBus
    
    class SagaStorage_Dir
        
        def initialize( uri )
            @sagaDir = uri.path

            inputDir = Dir.new( @sagaDir )
            if !File.writable?( @sagaDir ) then
                puts "***** Directory is not writable, #{@sagaDir}."
                puts "***** Make the directory, #{@sagaDir}, writable and try again."
                puts "***** Or, set the Saga Directory explicitly by, SAGA_URI=<dir://path/to/saga>"
                abort();
            end
            rescue Errno::ENOENT => e
            puts "***** Directory does not exist, #{@sagaDir}."
            puts "***** Create the directory, #{@sagaDir}, and try again."
            puts "***** eg, mkdir #{@sagaDir}"
            puts "***** Or, set the Saga Directory explicitly by, SAGA_URI=<dir://path/to/saga>"
            abort();
            rescue Errno::ENOTDIR => e
            puts "***** The specified path does not point to a directory, #{@sagaDir}."
            puts "***** Either repoint path to a directory, or remove, #{@sagaDir}, and create it as a directory."
            puts "***** eg, rm #{@sagaDir} && mkdir #{@sagaDir}"
            puts "***** Or, set the Saga Directory explicitly by, SAGA_URI=<dir://path/to/saga>"
            abort();
        end
        
        #Start
        def Begin
            @list = Array.new
            @deleted = Array.new
        end
        
        #Set
        def Set( data )
            path = self.getPath( data.correlationId )
            @list << Hash["path", path, "data", data]
        end
        
        #Get
        def Get( correlationId )
            path = self.getPath( correlationId )
            data = self.load( path )
            @list << Hash["path", path, "data", data]
            
            return data
        end
        
        #Finish
        def Commit
            @list.each do |e|
                File.open( e['path'], "w" ) { |f| f.write( YAML::dump( e['data'] ) ) }
            end
            @deleted.each do |correlationId|
                File.unlink( self.getPath( correlationId ) )
            end
        end
        
        def Rollback
        end
        
        def Delete( correlationId )
            @deleted << correlationId
        end
        
        #Detail Functions
        def getPath( correlationId )
            path = "#{@sagaDir}/saga-#{correlationId}"

            return path
        end
        
        def load( path )
            return Hash.new if !File.exists?( path )
            
            content = IO.read( path )
            
            return Hash.new if content == ""
            
            return YAML::load( content )
        end
        
        
    end
    
end
