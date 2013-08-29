module RServiceBus
    
    class State
        
        def initialize( path )
            @path = path
        end
        
        def get( name )
            return -1 unless @state.has_key?(name)
            
            return @state[name]
        end
        
        def set( name, value )
            @state[name] = value
        end
        
        def load
            if !File.exists?( @path ) then
                @state = Hash.new if !File.exists?( @path )
                return
            end
            
            content = IO.read( @path )
            if content == "" then
                @state = Hash.new
            end
            
            
            @state = YAML::load( content )
        end
        
        def save
            content = YAML::dump( @state )
            IO.write( @path, content )
        end
        
        def close
            
        end
        
    end
    
    
    class AppResource_State<AppResource
        
        def connect(uri)
            return State.new( uri.path )
        end

        # Transaction Semantics
        def Begin
            @connection.load
        end

        # Transaction Semantics
        def Commit
            @connection.save
        end
        
        # Transaction Semantics
        def Rollback
            @connection.load
        end
    end
    
end
