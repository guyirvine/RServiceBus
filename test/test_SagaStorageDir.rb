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
        self.Finish
	end


end

class Saga_Manager_For_Testing<RServiceBus::Saga_Manager
    attr_reader :correlation

end

class SagaStorage_Dir_For_Testing<RServiceBus::SagaStorage_Dir
    attr_reader :list
    
    def getCorrelationIdForFirstSaga
        return @list[0]['data'].correlationId
    end
    
    def getDataForFirstSaga
        return self.Get( @list[0]['data'].correlationId )
    end

end

class ResourceManager_For_Testing_Sagas<RServiceBus::ResourceManager
    
end


class SagaStorageDirTest < Test::Unit::TestCase
    
    def setup
        Dir.glob('/tmp/saga-*').each do |path|
            File.unlink( path )
        end


        @Bus = RServiceBus::Test_Bus.new

        @SagaStorage = SagaStorage_Dir_For_Testing.new( URI.parse('dir:///tmp/') )
        stateManager = nil
        @ResourceManager = ResourceManager_For_Testing_Sagas.new( stateManager, @SagaStorage )
        @sagaManager = Saga_Manager_For_Testing.new( @Bus, @ResourceManager, @SagaStorage )
        @msg1 = RServiceBus::Message.new( Msg1.new('One'), 'Q')

        @SagaStorage.Begin
    end

    def test_StartSaga
        assert_equal 0, Dir.glob('/tmp/saga-*').length

        @sagaManager.RegisterSaga( SagaMsg1Msg2 )

        @sagaManager.Handle( @msg1 )
        assert_equal 1, @SagaStorage.list.length
        data = @SagaStorage.list[0]['data']

        assert_equal 0, Dir.glob('/tmp/saga-*').length
        @SagaStorage.Commit
        assert_equal 1, Dir.glob('/tmp/saga-*').length
        assert_equal true, File.exists?( "/tmp/saga-#{data.correlationId}" )

        storedData = @SagaStorage.Get( data.correlationId )
        assert_equal 'John1', storedData['Bob1']
        assert_equal 'One', storedData['sfield2']

    end

    def test_SagaWithFollowUpMsg
        @sagaManager.RegisterSaga( SagaMsg1Msg2 )
        assert_equal 0, Dir.glob('/tmp/saga-*').length


        @sagaManager.Handle( @msg1 )
        @SagaStorage.Commit
        assert_equal 1, Dir.glob('/tmp/saga-*').length
        data = @SagaStorage.getDataForFirstSaga
        correlationid = data.correlationId
        assert_equal 'John1', data['Bob1']
        assert_equal "One", data["sfield2"]


        msg2 = RServiceBus::Message.new( Msg2.new( 'BB', "AA" ), "Q", correlationid )
        @sagaManager.Handle( msg2 )
        @SagaStorage.Commit
        assert_equal 1, Dir.glob( "/tmp/saga-*" ).length
        data = @SagaStorage.getDataForFirstSaga
        assert_equal "BB", data["Bob1"]
        assert_equal "BB", data["Bob2"]
        assert_equal "One", data["sfield2"]


    end

    def test_SagaWithFollowUpMsgAndFinish
        @sagaManager.RegisterSaga( SagaMsg1Msg2 )
        assert_equal 0, Dir.glob( "/tmp/saga-*" ).length


        @sagaManager.Handle( @msg1 )
        @SagaStorage.Commit
        assert_equal 1, Dir.glob( "/tmp/saga-*" ).length
        data = @SagaStorage.getDataForFirstSaga
        correlationid = data.correlationId
        assert_equal "John1", data["Bob1"]
        assert_equal "One", data["sfield2"]

        
        msg2 = RServiceBus::Message.new( Msg2.new( "BB", "AA" ), "Q", correlationid )
        @sagaManager.Handle( msg2 )
        @SagaStorage.Commit
        assert_equal 1, Dir.glob( "/tmp/saga-*" ).length
        data = @SagaStorage.getDataForFirstSaga
        assert_equal "BB", data["Bob1"]
        assert_equal "BB", data["Bob2"]
        assert_equal "One", data["sfield2"]
        
        
        msg3 = RServiceBus::Message.new( Msg3.new( "CC" ), 'Q', correlationid )

        @sagaManager.Handle( msg3 )
        
        @SagaStorage.Commit
        assert_equal 0, Dir.glob( "/tmp/saga-*" ).length

    end


end
