module RServiceBus

require "rservicebus/AppResource/Smb"

    class AppResource_SmbDir<AppResource_Smb

	def connect(uri)
		self.processUri
        remote = SMB.opendir( s, "b" )
		return remote	
	end

    end
    
end
