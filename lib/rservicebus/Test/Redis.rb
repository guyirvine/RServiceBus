module RServiceBus
    
    class Test_Redis
        
        @keyHash
        
        def initialize
            @keyHash = Hash.new
        end
        
        def getAll
            return @keyHash
        end
        
        def get( key )
            return @keyHash[key]
        end
        
        def set( key, value )
            @keyHash[key] = value
        end
        
        def sadd( key, value )
            @keyHash[key] = Array.new if @keyHash[key].nil?

            @keyHash[key] << value
            @keyHash[key] = @keyHash[key].uniq
        end
        
        def smembers( key )
            return @keyHash[key]
        end
        
        def sismember( key, value )
            return false if @keyHash[key].nil?
            
            @keyHash[key].each do |v|
                return true if v == value
            end
            
            return false
        end
        
        def srem( key, value )
            return if @keyHash[key].nil?

            @keyHash[key].delete value
        end

        def incr( key )
			@keyHash[key] = 0 unless @keyHash.has_key?(key)
            
            @keyHash[key] = @keyHash[key] + 1
            return @keyHash[key]
        end
        
        def del( key )
            @keyHash.delete( key )
        end
        
    end
    
end
