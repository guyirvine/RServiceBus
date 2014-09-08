module RServiceBus
    
    class SendAtStorage_File
        
        def initialize( uri )
            @list = self.load( uri.path )
        end
        def load( path )
            return Array.new unless File.exists?(path)

            content = IO.read( path )

            return Array.new if content == ''

            return YAML::load( content )
        end


        #Add
        def Add( msg )
            @list << msg
            self.Save
        end
        
        #GetAll
        def GetAll
            return @list
        end
        
        #Delete
        def Delete( idx )
            @list.delete_at( idx )
            self.Save
        end
        
        #Finish
        def Save
            content = YAML::dump( @list )
            File.open( @uri.path, 'w') { |f| f.write( YAML::dump( content ) ) }
        end
        
        
        
    end
    
end
