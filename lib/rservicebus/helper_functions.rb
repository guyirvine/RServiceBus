module RServiceBus


	def RServiceBus.convertDTOToHash( obj )
		hash = {};
		obj.instance_variables.each {|var| hash[var.to_s.delete('@')] = obj.instance_variable_get(var) }

		return hash
	end

	def RServiceBus.convertDTOToJson( obj )
		hash = RServiceBus.convertDTOToHash(obj)

		return hash.to_json
	end

	def RServiceBus.log(string, ver=false)
        return if RServiceBus.checkEnvironmentVariable('TESTING')

		type = ver ? 'VERB' : 'INFO'
        if RServiceBus.checkEnvironmentVariable('VERBOSE') || !ver then
            timestamp = Time.new.strftime('%Y-%m-%d %H:%M:%S')
            puts "[#{type}] #{timestamp} :: #{string}"
        end
	end

    def RServiceBus.rlog(string)
        if RServiceBus.checkEnvironmentVariable('RSBVERBOSE') then
            timestamp = Time.new.strftime('%Y-%m-%d %H:%M:%S')
            puts "[RSB] #{timestamp} :: #{string}"
        end
    end

    def RServiceBus.createAnonymousClass( name_for_class )
        newAnonymousClass = Class.new(Object)
        Object.const_set( name_for_class, newAnonymousClass )
        return Object.const_get( name_for_class ).new
    end

    def RServiceBus.getValue( name, default=nil )
        value = ( ENV[name].nil?  || ENV[name] == '') ? default : ENV[name];
        log "Env value: #{name}: #{value}"
        return value
    end

    def RServiceBus.sendMsg( msg, responseQueue='agent')
        require 'rservicebus/EndpointMapping'
        endpointMapping = EndpointMapping.new
        endpointMapping.Configure
        queueName = endpointMapping.get( msg.class.name )

        ENV['RSBMQ'] = 'beanstalk://localhost' if ENV['RSBMQ'].nil?
        agent = RServiceBus::Agent.new
        Audit.new( agent ).audit( msg )
        agent.sendMsg(msg, queueName, responseQueue)

        rescue QueueNotFoundForMsg=>e
		msg = "\n"
		msg = "#{msg}*** Queue not found for, #{e.message}\n"
		msg = "#{msg}*** Ensure you have an environment variable set for this Message Type, eg, \n"
		msg = "#{msg}*** MESSAGE_ENDPOINT_MAPPINGS=#{e.message}:<QueueName>\n"
		raise StandardError.new( msg )
    end

    def RServiceBus.sendMsg( msg, responseQueue='agent')
        require 'rservicebus/EndpointMapping'
        endpointMapping = EndpointMapping.new
        endpointMapping.Configure
        queueName = endpointMapping.get( msg.class.name )

        ENV['RSBMQ'] = 'beanstalk://localhost' if ENV['RSBMQ'].nil?
        agent = RServiceBus::Agent.new
        Audit.new( agent ).auditOutgoing( msg )
        agent.sendMsg(msg, queueName, responseQueue)

        rescue QueueNotFoundForMsg=>e
		msg = "\n"
		msg = "#{msg}*** Queue not found for, #{e.message}\n"
		msg = "#{msg}*** Ensure you have an environment variable set for this Message Type, eg, \n"
		msg = "#{msg}*** MESSAGE_ENDPOINT_MAPPINGS=#{e.message}:<QueueName>\n"
		raise StandardError.new( msg )
    end

    def RServiceBus.checkForReply( queueName )
        ENV['RSBMQ'] = 'beanstalk://localhost' if ENV['RSBMQ'].nil?
        agent = RServiceBus::Agent.new
        msg = agent.checkForReply( queueName )
        Audit.new( agent ).auditIncoming( msg )

        return msg
    end

    def RServiceBus.tick( string )
        puts "[TICK] #{Time.new.strftime( '%Y-%m-%d %H:%M:%S.%6N' )} :: #{caller[0]}. #{string}"
    end

    def RServiceBus.checkEnvironmentVariable( string )
        return false if ENV[string].nil?
        return true if ENV[string] == true || ENV[string] =~ (/(true|t|yes|y|1)$/i)
        return false if ENV[string] == false || ENV[string].nil? || ENV[string] =~ (/(false|f|no|n|0)$/i)
        raise ArgumentError.new("invalid value for Environment Variable: \"#{string}\"")
    end
end
