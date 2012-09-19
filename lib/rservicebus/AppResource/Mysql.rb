module RServiceBus
    
    require "mysql2"
    
    #Implementation of an AppResource - Redis
    class AppResource_Mysql<AppResource
        
        @connection
        
        def connect()
            uri = self.uri
            host = uri.host
            database = uri.path.sub( "/", "" )


            @connection = Mysql2::Client.new(:host => uri.host,
                                             :database => uri.path.sub( "/", "" ),
                                             :username => uri.user )
            puts "AppResource_Mysql. Connected to, " + uri.to_s
        end

        def initialize( uri )
            super(uri)
            self.connect
        end

        def getResource
            return @connection
        end

    end
    
end

end
