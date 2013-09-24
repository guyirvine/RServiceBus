module RServiceBus
require "net/smb"


    class AppResource_Smb<AppResource

	def processUri
		host = @uri.host

		parts = @uri.path.split( "/" )
		parts.shift
		share = parts.shift
		path = parts.join( "/" )
		
		@clean_path = "smb://#{host}/#{share}/#{URI.decode(path)}"

		@smb = Net::SMB.new
		@smb.auth_callback {|host, share|
			  [@uri.user,@uri.password]
		}
	end
    end 
end
