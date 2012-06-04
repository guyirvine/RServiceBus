module RServiceBus

	def RServiceBus.convertDTOToJson( obj )
		hash = {}; 
		obj.instance_variables.each {|var| hash[var.to_s.delete("@")] = obj.instance_variable_get(var) }
	
		newOne = hash.to_json

		return newOne
	end

end