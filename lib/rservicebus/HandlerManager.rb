module RServiceBus
    
    #Given a directory, this class is responsible for finding
    #	msgnames,
    #	handlernames, and
    #	loading handlers
    class HandlerManager
        
        # Constructor
        #
        # @param [RServiceBus::Host] host instance
        # @param [Hash] appResources As hash[k,v] where k is the name of a resource, and v is the resource
        def initialize( host, resourceManager, stateManager )
            @host = host
            @resourceManager = resourceManager
            @stateManager = stateManager
            
            @handlerList = Hash.new
            @resourceListByHandlerName = Hash.new
        end
        
        
        # setBusAttributeIfRequested
        #
        # @param [RServiceBus::Handler] handler
        def setBusAttributeIfRequested( handler )
            if defined?( handler.Bus ) then
                handler.Bus = @host
                RServiceBus.log 'Bus attribute set for: ' + handler.class.name
            end
            
            return self
        end
        
        # setStateAttributeIfRequested
        #
        # @param [RServiceBus::Handler] handler
        def setStateAttributeIfRequested( handler )
            if defined?( handler.State ) then
                handler.State = @stateManager.Get( handler )
                RServiceBus.log 'Bus attribute set for: ' + handler.class.name
            end
            
            return self
        end
        
        # checkIfStateAttributeRequested
        #
        # @param [RServiceBus::Handler] handler
        def checkIfStateAttributeRequested( handler )
            @stateManager.Required if defined?( handler.State )
            
            return self
        end
        
        def interrogateHandlerForAppResources( handler )
            RServiceBus.rlog "Checking app resources for: #{handler.class.name}"
            RServiceBus.rlog "If your attribute is not getting set, check that it is in the 'attr_accessor' list"

            @resourceListByHandlerName[handler.class.name] = Array.new
            @resourceManager.getAll.each do |k,v|
                if handler.class.method_defined?( k ) then
                    @resourceListByHandlerName[handler.class.name] << k
                    RServiceBus.log "Resource attribute, #{k}, found for: " + handler.class.name
                end
            end
            
            return self
        end
        
        def addHandler( msgName, handler )
            @handlerList[msgName] = Array.new if @handlerList[msgName].nil?
            return unless @handlerList[msgName].index{ |x| x.class.name == handler.class.name }.nil?
            
            @handlerList[msgName] << handler
            self.setBusAttributeIfRequested( handler )
            self.checkIfStateAttributeRequested( handler )
            self.interrogateHandlerForAppResources( handler )
        end
        
        # As named
        #
        # @param [String] msgName
        ## @param [Array] appResources A list of appResource
        def getListOfResourcesNeededToProcessMsg( msgName )
            return Array.new if @handlerList[msgName].nil?

            list = Array.new
            @handlerList[msgName].each do |handler|
                list = list + @resourceListByHandlerName[handler.class.name] unless @resourceListByHandlerName[handler.class.name].nil?
            end
            list.uniq!
            
            return list
        end

        def setResourcesForHandlersNeededToProcessMsg( msgName )
            @handlerList[msgName].each do |handler|
                self.setStateAttributeIfRequested( handler )
                
                next if @resourceListByHandlerName[handler.class.name].nil?
                @resourceListByHandlerName[handler.class.name].each do |k|
                    handler.instance_variable_set( "@#{k}", @resourceManager.get(k).getResource() )
                    RServiceBus.rlog "App resource attribute, #{k}, set for: " + handler.class.name
                end
            end
            
        end
        
        def getHandlerListForMsg( msgName )
            #            raise NoHandlerFound.new( msgName ) if @handlerList[msgName].nil?
            return Array.new if @handlerList[msgName].nil?


            list = self.getListOfResourcesNeededToProcessMsg( msgName )
            self.setResourcesForHandlersNeededToProcessMsg( msgName )
            
            return @handlerList[msgName]
        end
        
        def canMsgBeHandledLocally( msgName )
            return @handlerList.has_key?(msgName)
        end
        
        def getStats
            list = Array.new
            @handlerList.each do |k,v|
                list << v.inspect
            end
            
            return list
        end
        
        def getListOfMsgNames
            return @handlerList.keys
        end
        
        
    end
end
