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
        def initialize( host, appResources, stateManager )
            @host = host
            @appResources = appResources
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
                RServiceBus.log "Bus attribute set for: " + handler.class.name
            end
            
            return self
        end
        
        # setStateAttributeIfRequested
        #
        # @param [RServiceBus::Handler] handler
        def setStateAttributeIfRequested( handler )
            if defined?( handler.State ) then
                handler.State = @stateManager.Get( handler )
                RServiceBus.log "Bus attribute set for: " + handler.class.name
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
            @appResources.each do |k,v|
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
        
        # Assigns appropriate resources to writable attributes in the handler that match keys in the resource hash
        #
        # @param [RServiceBus::Handler] handler
        ## @param [Hash] appResources As hash[k,v] where k is the name of a resource, and v is the resource
        def setAppResources_to_be_removed( handler )
            RServiceBus.rlog "Checking app resources for: #{handler.class.name}"
            RServiceBus.rlog "If your attribute is not getting set, check that it is in the 'attr_accessor' list"
            @appResources.each do |k,v|
                if handler.class.method_defined?( k ) then
                    v._connect
                    #                    v.Begin
                    handler.instance_variable_set( "@#{k}", v.getResource() )
                    RServiceBus.log "App resource attribute, #{k}, set for: " + handler.class.name
                end
            end
            
            return self
        end
        
        def getListOfResourcesNeededToProcessMsg( msgName )
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
                    handler.instance_variable_set( "@#{k}", @appResources[k].getResource() )
                    RServiceBus.rlog "App resource attribute, #{k}, set for: " + handler.class.name
                end
            end
            
        end
        
        def getHandlerListForMsg( msgName )
            raise NoHandlerFound.new( msgName ) if @handlerList[msgName].nil?
            
            @stateManager.Begin
            list = self.getListOfResourcesNeededToProcessMsg( msgName )
            list.each do |resourceName|
                r = @appResources[resourceName]
                r._connect
                r.Begin
                RServiceBus.rlog "Preparing resource: #{resourceName}. Begin"
            end
            
            self.setResourcesForHandlersNeededToProcessMsg( msgName )
            
            return @handlerList[msgName]
        end
        
        def commitResourcesUsedToProcessMsg( msgName )
            RServiceBus.rlog "HandlerManager.commitResourcesUsedToProcessMsg, #{msgName}"
            list = self.getListOfResourcesNeededToProcessMsg( msgName )
            list.each do |resourceName|
                r = @appResources[resourceName]
                RServiceBus.rlog "Commit resource, #{r.class.name}"
                r.Commit
                r.finished
            end
            @stateManager.Commit
        end
        
        def rollbackResourcesUsedToProcessMsg( msgName )
            RServiceBus.rlog "HandlerManager.rollbackResourcesUsedToProcessMsg, #{msgName}"
            list = self.getListOfResourcesNeededToProcessMsg( msgName )
            list.each do |resourceName|
                begin
                    r = @appResources[resourceName]
                    RServiceBus.rlog "Rollback resource, #{r.class.name}"
                    r.Rollback
                    r.finished
                    rescue Exception => e1
                    @host.log "Caught nested exception rolling back, #{r.class.name}, for msg, #{msgName}"
                    @host.log "****"
                    @host.log e1.message
                    @host.log e1.backtrace
                    @host.log "****"
                end
            end
            
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
