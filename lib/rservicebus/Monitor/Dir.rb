require 'cgi'

class Monitor_Dir<Monitor
    
    @Path
    @ArchiveDir
    
    def connect(uri)
        #Pass the path through the Dir object to check syntax on startup
        inputDir = Dir.new( uri.path )
        @Path = inputDir.path
        
        return if uri.query.nil?
        parts = CGI.parse(uri.query)
        return if parts["archive"].nil?
        
        archiveUri = URI.parse( parts["archive"][0] )
        if !File.directory?( archiveUri.path ) then
            puts "***** Archive file name templating not yet supported."
            puts "***** Directory's only."
            abort()
        end
        
        @ArchiveDir = archiveUri.path
        
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

            if @ArchiveDir.nil? then
                File.unlink( file )
                else
                basename = File.basename( file )
                newFilePath = @ArchiveDir + "/" + basename + "." + DateTime.now.strftime( "%Y%m%d%H%M%S%L")
                @Bus.log "Writing to archive, #{newFilePath}", true
                File.rename( file, newFilePath )
            end
        end
        
    end
    
end
