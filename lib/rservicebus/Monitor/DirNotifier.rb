require 'cgi'
require 'fileutils'
require 'pathname'

module RServiceBus

    class Monitor_DirNotifier<Monitor

        attr_reader :Path, :ProcessingFolder, :Filter

        def connect(uri)
            #Pass the path through the Dir object to check syntax on startup
            begin
                self.open_folder uri.path
                unless self.file_writable?(uri.path) then
                  puts "***** Directory is not writable, #{uri.path}."
                  puts "***** Make the directory, #{uri.path}, writable and try again."
                  abort()
                end
                rescue Errno::ENOENT => e
                    puts "***** Directory does not exist, #{uri.path}."
                    puts "***** Create the directory, #{uri.path}, and try again."
                    puts "***** eg, mkdir #{uri.path}"
                    abort()
                rescue Errno::ENOTDIR => e
                puts "***** The specified path does not point to a directory, #{uri.path}."
                puts "***** Either repoint path to a directory, or remove, #{uri.path}, and create it as a directory."
                puts "***** eg, rm #{uri.path} && mkdir #{uri.path}"
                abort()
            end

            @Path = uri.path

            if uri.query.nil?
                puts '***** Processing Directory is not specified.'
                puts '***** Specify the Processing Directory as a query string in the Path URI'
                puts "***** eg, '/#{uri.path}?processing=*ProcessingDir*"
                abort()
            else
                parts = CGI.parse(uri.query)

                if parts.has_key? 'processing' then
                    processingUri = URI.parse parts['processing'][0]
                    begin
                        self.open_folder processingUri.path
                        unless self.file_writable?(processingUri.path) then
                          puts "***** Processing Directory is not writable, #{processingUri.path}."
                          puts "***** Make the directory, #{processingUri.path}, writable and try again."
                          abort()
                        end
                        rescue Errno::ENOENT => e
                            puts "***** Processing Directory does not exist, #{processingUri.path}."
                            puts "***** Create the directory, #{processingUri.path}, and try again."
                            puts "***** eg, mkdir #{processingUri.path}"
                            abort()
                        rescue Errno::ENOTDIR => e
                            puts "***** Processing Directory does not point to a directory, #{processingUri.path}."
                            puts "***** Either repoint path to a directory, or remove, #{processingUri.path}, and create it as a directory."
                            puts "***** eg, rm #{processingUri.path} && mkdir #{processingUri.path}"
                            abort()
                    end

                    @ProcessingFolder = processingUri.path
                end

                @Filter = '*'
                if parts.has_key? 'filter' then
                    @Filter = parts['filter'][0]
                end
            end
        end

        def Look
            fileList = self.get_files
            fileList.each do |filePath|
                newPath = self.move_file(filePath, @ProcessingFolder)
                self.send( nil, URI.parse( "file://#{newPath}" ) )
            end
        end

        def file_writable? path
            return File.writable? path
        end

        def open_folder path
            Dir.new path
        end

        def move_file src, dest
            FileUtils.mv(src, dest)
            filename = Pathname.new(src).basename
            return Pathname.new(dest).join(filename)
        end

        def get_files
            return Dir.glob( Pathname.new("#{@Path}").join(@Filter) ).select { |f| File.file?(f) }
        end

    end
end
