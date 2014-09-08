require 'test/unit'

require './lib/rservicebus/Saga/Base.rb'
require './lib/rservicebus/Saga/Manager.rb'
require './lib/rservicebus/Message.rb'
require './lib/rservicebus/Saga/Data.rb'
require './lib/rservicebus/ResourceManager.rb'

require 'rservicebus/SagaStorage/InMemory.rb'
require 'rservicebus/SagaStorage/Dir.rb'

require './lib/rservicebus/Test/Bus'

class Msg1
    attr_accessor :field1
    
    def initialize( field1 )
        @field1 = field1
    end
end

class Msg2
    attr_reader :field2, :field3
    
    def initialize( field2, field3 )
        @field2 = field2
        @field3 = field3
    end
end

class Msg3
    attr_accessor :field1
    
    def initialize( field1 )
        @field1 = field1
    end
end

class SagaMsg1Msg2<RServiceBus::Saga_Base
    
	def StartWith_Msg1( msg )
        self.data['Bob1'] = 'John1'
        self.data['sfield2'] = msg.field1
	end
	def Handle_Msg2( msg )
        self.data['Bob1'] = msg.field2
        self.data['Bob2'] = msg.field2
	end
	def Handle_Msg3( msg )
        self.finish
	end


end

class Saga_Manager_For_Testing<RServiceBus::Saga_Manager
    attr_reader :correlation, :resourceManager

end

class SagaStorage_InMemory_For_Testing<RServiceBus::SagaStorage_InMemory
    attr_reader :hash
    
end

class ResourceManager_For_Testing_Sagas<RServiceBus::ResourceManager
    
end


class SagaTest < Test::Unit::TestCase
    
    def setup
        @Bus = RServiceBus::Test_Bus.new
        stateManager = nil

        @SagaStorage = SagaStorage_InMemory_For_Testing.new('')
        stateManager = nil
        @ResourceManager = ResourceManager_For_Testing_Sagas.new( stateManager, @SagaStorage )
        @sagaManager = Saga_Manager_For_Testing.new( @Bus, @ResourceManager, @SagaStorage )
        
        @msg1 = RServiceBus::Message.new( Msg1.new('One'), 'Q')

        @SagaStorage.Begin
    end
    
	def test_SagaMsgDerivation
		assert_equal ['Msg1'], @sagaManager.GetStartWithMethodNames( SagaMsg1Msg2 )
        
	end
    
    
    def test_StartSaga
        @sagaManager.RegisterSaga( SagaMsg1Msg2 )

        assert_equal 0, @SagaStorage.hash.keys.length
        @sagaManager.Handle( @msg1 )
        assert_equal 1, @SagaStorage.hash.keys.length
        
        data = @SagaStorage.hash[@SagaStorage.hash.keys[0]]
        assert_equal 2, data.length
        
        data = @SagaStorage.hash[@SagaStorage.hash.keys[0]]
        assert_equal 2, data.length
        
        assert_equal 'John1', data['Bob1']
        assert_equal 'One', data['sfield2']
        
        
    end
    
    def test_SagaWithFollowUpMsg
        @sagaManager.RegisterSaga( SagaMsg1Msg2 )

        @sagaManager.Handle( @msg1 )
        assert_equal 1, @SagaStorage.hash.keys.length


        msg2 = RServiceBus::Message.new( Msg2.new( 'BB', 'AA'), 'Q', @SagaStorage.hash.keys[0] )


        @sagaManager.Handle( msg2 )

        data = @SagaStorage.hash[@SagaStorage.hash.keys[0]]
        assert_equal 3, data.length

        assert_equal 'BB', data['Bob1']
        assert_equal 'BB', data['Bob2']
        assert_equal 'One', data['sfield2']


    end

    def test_SagaWithFollowUpMsgAndFinish
        @sagaManager.RegisterSaga( SagaMsg1Msg2 )

        @sagaManager.Handle( @msg1 )
        assert_equal 1, @SagaStorage.hash.keys.length

        msg2 = RServiceBus::Message.new( Msg2.new( "BB", "AA" ), "Q", @SagaStorage.hash.keys[0] )
        @sagaManager.Handle( msg2 )
        assert_equal 3, @SagaStorage.hash[@SagaStorage.hash.keys[0]].length

        msg3 = RServiceBus::Message.new( Msg3.new( "CC" ), "Q", @SagaStorage.hash.keys[0] )

        @sagaManager.Handle( msg3 )
        
        @SagaStorage.Commit
        assert_equal 0, @SagaStorage.hash.length

    end


end
