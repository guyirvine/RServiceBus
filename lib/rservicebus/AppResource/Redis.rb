module RServiceBus
    
    require "redis"
    
    #Implementation of an AppResource - Redis
    class AppResource_Redis<AppResource
        
        def connect(uri)
            port = uri.port || 6379

            return Redis.new( :host=>uri.host, :port=>port )
        end

        def finished
            @connection.quit
        end
    end
    
end