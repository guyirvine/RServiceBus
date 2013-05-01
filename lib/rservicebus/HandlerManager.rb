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
        def initialize( host, appResources )
            @host = host
            @appResources = appResources
            
            @handlerList = Hash.new
            @resourceListByHandlerName = Hash.new
        end
        
        
        # setBusAttributeIfRequested
        #
        # @param [RServiceBus::Handler] handler
        def setBusAttributeIfRequested( handler )
            if defined?( handler.Bus ) then
                handler.Bus = @host
                @host.log "Bus attribute set for: " + handler.class.name
            end
            
            return self
        end

        def interrogateHandlerForAppResources( handler )
            @host.log "Checking app resources for: #{handler.class.name}", true
            @host.log "If your attribute is not getting set, check that it is in the 'attr_accessor' list", true
            
            @resourceListByHandlerName[handler.class.name] = Array.new
            @appResources.each do |k,v|
                if handler.class.method_defined?( k ) then
                    @resourceListByHandlerName[handler.class.name] << k
                    @host.log "Resource attribute, #{k}, found for: " + handler.class.name
                end
            end
            
            return self
        end
        
        def addHandler( msgName, handler )
            @handlerList[msgName] = Array.new if @handlerList[msgName].nil?
            return unless @handlerList[msgName].index{ |x| x.class.name == handler.class.name }.nil?

            @handlerList[msgName] << handler
            self.setBusAttributeIfRequested( handler )
            self.interrogateHandlerForAppResources( handler )
        end
        
        # Assigns appropriate resources to writable attributes in the handler that match keys in the resource hash
        #
        # @param [RServiceBus::Handler] handler
        ## @param [Hash] appResources As hash[k,v] where k is the name of a resource, and v is the resource
        def setAppResources( handler )
            @host.log "Checking app resources for: #{handler.class.name}", true
            @host.log "If your attribute is not getting set, check that it is in the 'attr_accessor' list", true
            @appResources.each do |k,v|
                if handler.class.method_defined?( k ) then
                    v._connect
                    v.Begin
                    handler.instance_variable_set( "@#{k}", v.getResource() )
                    @host.log "App resource attribute, #{k}, set for: " + handler.class.name
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
                next if @resourceListByHandlerName[handler.class.name].nil?
                @resourceListByHandlerName[handler.class.name].each do |k|
                    handler.instance_variable_set( "@#{k}", @appResources[k].getResource() )
                    @host.log "App resource attribute, #{k}, set for: " + handler.class.name
                end
            end
            
        end
        
        def getHandlerListForMsg( msgName )
            raise NoHandlerFound.new( msgName ) if @handlerList[msgName].nil?

            list = self.getListOfResourcesNeededToProcessMsg( msgName )
            list.each do |resourceName|
                @host.log( "Preparing reousrce: #{resourceName}", true )
                r = @appResources[resourceName]
                r._connect
                r.Begin
            end
            
            self.setResourcesForHandlersNeededToProcessMsg( msgName )
            
            return @handlerList[msgName]
        end
        
        def commitResourcesUsedToProcessMsg( msgName )
            @host.log "HandlerManager.commitResourcesUsedToProcessMsg, #{msgName}", true
            list = self.getListOfResourcesNeededToProcessMsg( msgName )
            list.each do |resourceName|
                    r = @appResources[resourceName]
                    @host.log "Commit resource, #{r.class.name}", true
                    r.Commit
                    r.finished
            end
        end
        
        def rollbackResourcesUsedToProcessMsg( msgName )
            @host.log "HandlerManager.rollbackResourcesUsedToProcessMsg, #{msgName}", true
            list = self.getListOfResourcesNeededToProcessMsg( msgName )
            list.each do |resourceName|
                begin
                    r = @appResources[resourceName]
                    @host.log "Rollback resource, #{r.class.name}", true
                    r.Rollback
                    r.finished
                    rescue Exception => e1
                    @host.log "Caught nested exception rolling back, #{r.class.name}, for msg, #{msgName}"
                    @host.log "****"
                    @host.log e1.message
                    @host.log e.backtrace
                    @host.log "****"
                end
            end
            
        end
        
        def canMsgBeHandledLocally( msgName )
            return @handlerList.has_key?(msgName)
        end
    end
end
