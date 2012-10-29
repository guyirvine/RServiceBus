module RServiceBus
    
    require "mysql2"
    
    #Implementation of an AppResource - Redis
    class AppResource_Mysql<AppResource
        
        def connect(uri)
            return Mysql2::Client.new(:host => uri.host,
                                             :database => uri.path.sub( "/", "" ),
                                             :username => uri.user )
        end

    end
    
end

end
