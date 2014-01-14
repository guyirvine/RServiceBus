module RServiceBus


class Saga_Manager
    
	def initialize( host, resourceManager, sagaStorage )
		@handler = Hash.new
		@startWith = Hash.new
		@saga = Hash.new

		@host = host
 
        @resourceManager = resourceManager
        @resourceListBySagaName = Hash.new
        
        @sagaStorage = sagaStorage
	end
    
	def GetMethodsByPrefix( saga, prefix )
        list = []
        saga.instance_methods.each do |name|
            list.push name.to_s.sub( prefix, "" ) if name.to_s.slice( 0,prefix.length ) == prefix
        end
        
        return list
	end
    
	def GetStartWithMethodNames( saga )
		return self.GetMethodsByPrefix( saga, "StartWith_" )
	end
    
    # setBusAttributeIfRequested
    #
    # @param [RServiceBus::Saga] saga
    def setBusAttributeIfRequested( saga )
        if defined?( saga.Bus ) then
            saga.Bus = @host
            RServiceBus.log "Bus attribute set for: " + saga.class.name
        end
        
        return self
    end
    
    def interrogateSagaForAppResources( saga )
        RServiceBus.rlog "Checking app resources for: #{saga.class.name}"
        RServiceBus.rlog "If your attribute is not getting set, check that it is in the 'attr_accessor' list"
        
        @resourceListBySagaName[saga.class.name] = Array.new
        @resourceManager.getAll.each do |k,v|
            if saga.class.method_defined?( k ) then
                @resourceListBySagaName[saga.class.name] << k
                RServiceBus.log "Resource attribute, #{k}, found for: " + saga.class.name
            end
        end

        return self
    end


	def RegisterSaga( saga )
        s = saga.new
        self.setBusAttributeIfRequested( s )

		self.GetStartWithMethodNames( saga ).each do |msgName|
            @startWith[msgName] = Array.new if @startWith[msgName].nil?
            @startWith[msgName] << s

            RServiceBus.log "Registered, #{saga.name}, to StartWith, #{msgName}"
        end

		@saga[saga.name] = s
	end

    
    def prepSaga( saga )
        if !@resourceListBySagaName[saga.class.name].nil? then
            @resourceListBySagaName[saga.class.name].each do |k,v|
                saga.instance_variable_set( "@#{k}", resourceManager.get(k).getResource() )
                RServiceBus.rlog "App resource attribute, #{k}, set for: " + saga.class.name
            end
        end

    end

    def Handle( rmsg )
        @resourcesUsed = Hash.new
        handled = false
        msg = rmsg.msg

        RServiceBus.log "SagaManager, started processing, #{msg.class.name}", true
        if !@startWith[msg.class.name].nil? then
            @startWith[msg.class.name].each do |saga|
                data = Saga_Data.new( saga )
                @sagaStorage.Set( data )

                methodName = "StartWith_#{msg.class.name}"
                self.ProcessMsg( saga, data, methodName, msg )
                
                handled = true
            end
        end
        return handled if handled == true


        data = @sagaStorage.Get( rmsg.correlationId )
        return handled if data.nil?
        methodName = "Handle_#{msg.class.name}"
        saga = @saga[data.sagaClassName];
        self.ProcessMsg( saga, data, methodName, msg );


        return true
    end

    def ProcessMsg( saga, data, methodName, msg )
        @host.sagaData = data
        saga.data = data

        if saga.class.method_defined?( methodName ) then
            saga.send methodName, msg
        end

        if data.finished == true then
            @sagaStorage.Delete data.correlationId
        end

        @host.sagaData = nil
        #Save Data
    end
end


end

