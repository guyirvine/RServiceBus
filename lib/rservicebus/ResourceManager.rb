module RServiceBus
    
    #Co0ordinate Transactions across resources, handlers, and Sagas
    class ResourceManager

        # Constructor
        #
        def initialize( stateManager, sagaStorage )
            @appResources = Hash.new
            @currentResources = Hash.new
            @stateManager = stateManager
            @sagaStorage = sagaStorage
        end

        def add( name, res )
            @appResources[name] = res
        end

        def getAll
            return @appResources
        end

        def Begin
            @currentResources = Hash.new
            @stateManager.Begin
            @sagaStorage.Begin
        end

        def get( name )
            if @currentResources[name].nil? then
                r = @appResources[name]
                r._connect
                r.Begin
                RServiceBus.rlog "Preparing resource: #{resourceName}. Begin"
            end
            @currentResources[name] = @appResources[name]
            return @appResources[name]
        end

        def Commit( msgName )
            @stateManager.Commit
            @sagaStorage.Commit
            RServiceBus.rlog "HandlerManager.commitResourcesUsedToProcessMsg, #{msgName}"
            @currentResources.each do |k,v|
                RServiceBus.rlog "Commit resource, #{v.class.name}"
                v.Commit
                v.finished
            end
            
        end

        def Rollback( msgName )
            @sagaStorage.Rollback
            RServiceBus.rlog "HandlerManager.rollbackResourcesUsedToProcessMsg, #{msgName}"
            @currentResources.each do |k,v|
                begin
                    RServiceBus.rlog "Rollback resource, #{v.class.name}"
                    v.Rollback
                    v.finished
                    rescue Exception => e1
                    @host.log "Caught nested exception rolling back, #{v.class.name}, for msg, #{msgName}"
                    @host.log "****"
                    @host.log e1.message
                    @host.log e1.backtrace
                    @host.log "****"
                end
            end
            
        end
        
    end
end
