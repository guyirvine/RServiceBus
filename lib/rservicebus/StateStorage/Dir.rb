module RServiceBus
    
    class StateStorage_Dir
        
        def initialize( uri )
            @stateDir = uri.path
            
            inputDir = Dir.new( @stateDir )
            if !File.writable?( @stateDir ) then
                puts "***** Directory is not writable, #{@stateDir}."
                puts "***** Make the directory, #{@stateDir}, writable and try again."
                puts "***** Or, set the State Directory explicitly by, STATE_URI=<dir://path/to/state>"
                abort();
            end
            rescue Errno::ENOENT => e
            puts "***** Directory does not exist, #{@stateDir}."
            puts "***** Create the directory, #{@stateDir}, and try again."
            puts "***** eg, mkdir #{@stateDir}"
            puts "***** Or, set the State Directory explicitly by, STATE_URI=<dir://path/to/state>"
            abort();
            rescue Errno::ENOTDIR => e
            puts "***** The specified path does not point to a directory, #{@stateDir}."
            puts "***** Either repoint path to a directory, or remove, #{@stateDir}, and create it as a directory."
            puts "***** eg, rm #{@stateDir} && mkdir #{@stateDir}"
            puts "***** Or, set the State Directory explicitly by, STATE_URI=<dir://path/to/state>"
            abort();
        end
        
        #Start
        def Begin
            @list = Array.new
        end
        
        #Get
        def Get( handler )
            path = self.getPath( handler )
            hash = self.load( path )
            @list << Hash["path", path, "hash", hash]
            
            return hash
        end
        
        #Finish
        def Commit
            @list.each do |e|
                File.open( e['path'], "w" ) { |f| f.write( YAML::dump( e['hash'] ) ) }
            end
        end
        
        #Detail Functions
        def getPath( handler )
            path = "#{@stateDir}/#{handler.class.name}"
            
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
