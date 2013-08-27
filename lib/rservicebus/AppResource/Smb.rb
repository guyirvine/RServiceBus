module RServiceBus
require "net/smb"


    class AppResource_Smb<AppResource

        def connect(uri)
            begin
                remote = smb.open( uri.path, "b" )
                #if !File.writable?( uri.path ) then
                #    puts "*** Warning. Directory is not writable, #{uri.path}."
                #    puts "*** Warning. Make the directory, #{uri.path}, writable and try again."
                #end
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
            
            return remote;
        end
        
    end
    
end
