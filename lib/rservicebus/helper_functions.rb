module RServiceBus

	def RServiceBus.convertDTOToHash( obj )
		hash = {}; 
		obj.instance_variables.each {|var| hash[var.to_s.delete("@")] = obj.instance_variable_get(var) }

		return hash
	end

	def RServiceBus.convertDTOToJson( obj )
		hash = RServiceBus.convertDTOToHash(obj)
	
		return hash.to_json
	end

end