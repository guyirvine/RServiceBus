
class Monitor_Dir<Monitor
    
    @Path

    def connect(uri)
        #Pass the path through the Dir object to check syntax on startup
        inputDir = Dir.new( uri.path )
        @Path = inputDir.path
    end

    def ProcessPath( path )
        return IO.read( path )
    end

    def ProcessFile( file )
        payload = self.ProcessPath( file )
        
        self.send( payload )
    end
    
    def Look
        Dir.glob( "#{@Path}/*" ).each do |file|
            self.ProcessFile( file )

            File.unlink( file )
        end
        
    end

end
