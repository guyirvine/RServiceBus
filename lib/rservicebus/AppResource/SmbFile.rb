module RServiceBus

require 'rservicebus/AppResource/Smb'

    class AppResource_SmbFile<AppResource_Smb

	def connect(uri)
		self.processUri
puts "@clean_path: #{@clean_path}"
                remote = @smb.open( @clean_path  )
		return remote	
	end

    end
    
end
