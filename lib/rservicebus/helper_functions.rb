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

	def RServiceBus.log(string, ver=false)
		type = ver ? "VERB" : "INFO"
        #		if @config.verbose || !ver then
        timestamp = Time.new.strftime( "%Y-%m-%d %H:%M:%S" )
        puts "[#{type}] #{timestamp} :: #{string}"
        #		end
	end
    
    def RServiceBus.createAnonymousClass( name_for_class )
        newAnonymousClass = Class.new(Object)
        Object.const_set( name_for_class, newAnonymousClass )
        return Object.const_get( name_for_class ).new
    end
    
    def RServiceBus.getValue( name, default=nil )
        value = ( ENV[name].nil?  || ENV[name] == ""  ) ? default : ENV[name];
        log "Env value: #{name}: #{value}"
        return value
    end

    def RServiceBus.sendMsg( msg, responseQueue="agent" )
	require "rservicebus/EndpointMapping"
	endpointMapping = EndpointMapping.new
	endpointMapping.Configure
	queueName = endpointMapping.get( msg.class.name )	

	agent = RServiceBus::Agent.new.getAgent( URI.parse( "beanstalk://127.0.0.1:11300" ) )	
	agent.sendMsg(msg, queueName, responseQueue)

    end
    
end
