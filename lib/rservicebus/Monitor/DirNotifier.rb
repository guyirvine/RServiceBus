require 'cgi'
require 'zip/zip'
require 'zlib'

module RServiceBus
    
    class Monitor_DirNotifier<Monitor
        
        @Path
        
        def connect(uri)
            #Pass the path through the Dir object to check syntax on startup
            begin
                inputDir = Dir.new( uri.path )
                if !File.writable?( uri.path ) then
                    puts "***** Directory is not writable, #{uri.path}."
                    puts "***** Make the directory, #{uri.path}, writable and try again."
                    abort()
                end
                rescue Errno::ENOENT => e
                    puts "***** Directory does not exist, #{uri.path}."
                    puts "***** Create the directory, #{uri.path}, and try again."
                    puts "***** eg, mkdir #{uri.path}"
                    abort();
                rescue Errno::ENOTDIR => e
                puts "***** The specified path does not point to a directory, #{uri.path}."
                puts "***** Either repoint path to a directory, or remove, #{uri.path}, and create it as a directory."
                puts "***** eg, rm #{uri.path} && mkdir #{uri.path}"
                abort();
            end
            
            @Path = inputDir.path
            
        end

        def Look
            
            fileList = Dir.glob( "#{@Path}/*" )
            fileList.each do |filePath|
                self.send( nil, URI.parse( "file://#{filePath}" ) )

            end
            
        end
        
    end
end
