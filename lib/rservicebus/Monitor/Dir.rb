require 'cgi'
require 'zip/zip'
require 'zlib'

module RServiceBus
    
    class Monitor_Dir<Monitor
        
        @Path
        @ArchiveDir
        @InputFilter
        @QueryStringParts
        
        def connect(uri)
            #Pass the path through the Dir object to check syntax on startup
            inputDir = Dir.new( uri.path )
            @Path = inputDir.path
            @InputFilter = Array.new
            
            return if uri.query.nil?
            parts = CGI.parse(uri.query)
            @QueryStringParts = parts
            if parts.has_key?("archive") then
                archiveUri = URI.parse( parts["archive"][0] )
                if !File.directory?( archiveUri.path ) then
                    puts "***** Archive file name templating not yet supported."
                    puts "***** Directory's only."
                    abort()
                end
                @ArchiveDir = archiveUri.path
            end
            
            if parts.has_key?("inputfilter") then
                if parts["inputfilter"].count > 1 then
                    puts "Too many inputfilters specified."
                    puts "*** ZIP, or GZ are the only valid inputfilters."
                    abort();
                end
                
                if parts["inputfilter"][0] == "ZIP" then
                    elsif parts["inputfilter"][0] == "GZ" then
                    elsif parts["inputfilter"][0] == "TAR" then
                    else
                    puts "Invalid inputfilter specified."
                    puts "*** ZIP, or GZ are the only valid inputfilters."
                    abort();
                end
                @InputFilter << parts["inputfilter"][0]
            end
            
            
        end
        
        def ProcessContent( content )
            return content
        end
        
        def ReadContentFromZipFile( filePath )
            zip = Zip::ZipInputStream::open(filePath)
            entry = zip.get_next_entry
            content = zip.read
            zip.close
            
            return entry, content
        end
        
        def ReadContentFromGzFile( filePath )
            gz = Zlib::GzipReader.open(filePath)
            return gz.read
        end
        
        def ReadContentFromTarFile( filePath )
            raise "Not supported yet"
            content = ""
            #            Gem::Package::TarReader.new( filePath ).each do |entry|
            #    content = entry.read
            return content
        end
        
        def ReadContentFromFile( filePath )
            content = ""
            if @InputFilter.length > 0 then
                if @InputFilter[0] == 'ZIP' then
                    entry, content = self.ReadContentFromZipFile( filePath )
                    elsif @InputFilter[0] == 'GZ' then
                    content = self.ReadContentFromGzFile( filePath )
                    elsif @InputFilter[0] == 'TAR' then
                    content = self.ReadContentFromTarFile( filePath )
                end
                
                else
                content = IO.read( filePath )
            end
            
            return content
        end
        
        def ProcessPath( filePath )
            content = self.ReadContentFromFile( filePath )
            payload = self.ProcessContent( content )
            
            self.send( payload, URI.parse( "file://#{filePath}" ) )
            return content
        end
        
        def Look
            fileProcessed = 0
            maxFilesProcessed = 10
            
            fileList = Dir.glob( "#{@Path}/*" )
            fileList.each do |filePath|
                @Bus.log "Ready to process, #{filePath}", true
                content = self.ProcessPath( filePath )
                
                if !@ArchiveDir.nil? then
                    basename = File.basename( filePath )
                    newFilePath = @ArchiveDir + "/" + basename + "." + DateTime.now.strftime( "%Y%m%d%H%M%S%L") + ".zip"
                    @Bus.log "Writing to archive, #{newFilePath}", true
                    
                    Zip::ZipOutputStream.open(newFilePath) {
                        |zos|
                        zos.put_next_entry(basename)
                        zos.puts content
                    }
                end
                File.unlink( filePath )
                
                fileProcessed = fileProcessed + 1
                @Bus.log "Processed #{fileProcessed} of #{fileList.length}.", true
                @Bus.log "Allow system tick #{self.class.name}", true
                return if fileProcessed >= maxFilesProcessed
            end
            
        end
        
    end
end
