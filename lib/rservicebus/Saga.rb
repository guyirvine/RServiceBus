module RServiceBus
    
    #Requirements for Saga.
    #
    #Technicalities
    #correlation: how to tie two independant msgs together in a single saga
    #
    #Multiple messages - Any of which can start the saga
    #Timeouts
    #Persistent Data between calls
    #Ability to "complete" a saga, but not compulsory to do so.
    
    
    require "uri"
    
    
    class Saga_Data_InMemory
        
        attr_reader :data_hash

        @data_hash
        
        def initialize
            @data_hash = Hash.new
        end
        
        def get( saga, msg, mapping )
            @data_hash[saga.class.name] = Hash.new if @data_hash[saga.class.name].nil?
            @data_hash[saga.class.name][msg.class.name] = Array.new if @data_hash[saga.class.name][msg.class.name].nil?

            if !mapping[msg.class.name].nil? then
                mapping[msg.class.name].each do |msgFieldName,sagaFieldName|
                    
                    @data_hash[saga.class.name][msg.class.name].each do |data|
                        if !data[sagaFieldName].nil? then
                            return data if msg.instance_variable_get(msgFieldName) == data[sagaFieldName]
                        end
                    end
                end
            end

            hash = Hash.new
            @data_hash[saga.class.name][msg.class.name].push( hash )
            return hash;
        end
        
    end
    
    # Wrapper base class for resources used by applications, allowing rservicebus to configure the resource
    # - dependency injection.
    #
    class Saga_Manager

        #correlation strategy
        #  correlation strategy return an instance of the saga.
        #  that way, we can return an existing one, or create a new one
        
        # Start with sagaid
        
        #        def Handle_MsgName( msg, data )
        
        #        end
        
        def initialize
            @sagas = Hash.new
            @saga_data = Saga_Data_InMemory.new
        end
        
        def getMsgNames( sagaClass )
            list = []
            sagaClass.instance_methods.each do |name|
                list.push name.to_s.sub( "Handle_", "" ) if name.to_s.slice( 0,7 ) == "Handle_"
            end
            
            return list
        end
        
        def addSaga( sagaClass )
            saga = sagaClass.new
            hash = Hash["saga", saga, "mapping", saga.mapping]
            self.getMsgNames( sagaClass ).each do |name|
                sagas[name] = Array.new if sagas[name].nil?
                @sagas[name].push( hash )
            end
        end

        def Handle( msg )
            return if @sagas[msg.class.name].nil?
            
            @sagas[msg.class.name].each do |hash|
                saga = hash["saga"]
                
                data = @saga_data.get( saga, msg, hash["mapping"] )
                
                saga.data = data
                saga.Handle( msg )
            end
            
        end
    end
    
    
    class Saga
        attr_accessor :data, :mapping
        attr_reader :data
        
        @data
        @mapping
        
        def initialize
            @mapping = Hash.new
            self.ConfigureHowToFindSaga
        end
        
        def ConfigureHowToFindSaga()
            throw StandardError.new( "ConfigureHowToFindSaga needs to be implemented" );
        end
        
        def ConfigureMapping( msg, sagaFieldName, msgFieldName);
            #            if !msg.has_attribute?( msgFieldName ) then
            #    raise StandardError.new( "Msg, #{msg.name}, doesn't have a field named, #{msgFieldName}" )
            #end
            @mapping[msg.name] = Hash.new if @mapping[msg.name].nil?
            @mapping[msg.name]["@" + msgFieldName] = sagaFieldName
        end
        
        def complete
        end
        
        def Handle( msg )
            methodName = "Handle_#{msg.class.name}"
            
            self.send methodName, msg
        end
    end
    
    class Saga_Manager
        
        
    end
end
