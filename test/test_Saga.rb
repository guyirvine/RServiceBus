require 'test/unit'
require './lib/rservicebus/Saga.rb'


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

class SimpleSagaMsg1<RServiceBus::Saga
    
	def Handle_Msg1( msg )
	end
    
    def ConfigureHowToFindSaga()
        self.ConfigureMapping( Msg1, "sfield1", "field1")
    end
end

class SimpleSagaMsg2<RServiceBus::Saga
    
	def Handle_Msg2( msg )
	end
    
    def ConfigureHowToFindSaga()
        self.ConfigureMapping( Msg2, "sfield2", "field2")
    end
end

class DblSagaMsg1Msg2<RServiceBus::Saga
    
	def Handle_Msg1( msg )
        self.data["Bob1"] = "John1"
        self.data["sfield2"] = msg.field1
	end
	def Handle_Msg2( msg )
        self.data["Bob2"] = "John2"
	end

    def ConfigureHowToFindSaga()
        self.ConfigureMapping( Msg2, "sfield2", "field3")
    end
end

class Saga_Manager_For_Testing<RServiceBus::Saga_Manager
    attr_reader :sagas, :saga_data, :sagaMapping

    def getDataListForSaga( sagaName )
        return @saga_data.data_hash[sagaName].first[1]
    end

end

class SagaTest < Test::Unit::TestCase
    
    def setup
        
    end
    
	def test_SagaMsgDerivation
        @sagaManager = Saga_Manager_For_Testing.new
        
		assert_equal ["Msg1"], @sagaManager.getMsgNames( SimpleSagaMsg1 )
        
		assert_equal ["Msg2"], @sagaManager.getMsgNames( SimpleSagaMsg2 )
        
		assert_equal ["Msg1", "Msg2"], @sagaManager.getMsgNames( DblSagaMsg1Msg2 )
        
	end
    
	def test_SagasHandleMsg
        @sagaManager = Saga_Manager_For_Testing.new
        @sagaManager.addSaga( SimpleSagaMsg1 )
        @sagaManager.addSaga( SimpleSagaMsg2 )
        @sagaManager.addSaga( DblSagaMsg1Msg2 )
        
        assert_equal 2, @sagaManager.sagas.length

        assert_equal 2, @sagaManager.sagas["Msg1"].length
        assert_equal SimpleSagaMsg1.name, @sagaManager.sagas["Msg1"][0]["saga"].class.name
        assert_equal DblSagaMsg1Msg2.name, @sagaManager.sagas["Msg1"][1]["saga"].class.name

        assert_equal SimpleSagaMsg2.name, @sagaManager.sagas["Msg2"][0]["saga"].class.name
        
	end
    
	def test_SagaWithSingleInstance
        @sagaManager = Saga_Manager_For_Testing.new
        @sagaManager.addSaga( DblSagaMsg1Msg2 )
        
        @sagaManager.Handle( Msg1.new( "One" ) )
        @sagaManager.Handle( Msg2.new( "Two", "One" ) )

        
		assert_equal 1, @sagaManager.saga_data.data_hash["DblSagaMsg1Msg2"]["Msg2"][0].length
        
	end
    
	def test_SagaWithTwoInstancesSerial
        @sagaManager = Saga_Manager_For_Testing.new
        @sagaManager.addSaga( DblSagaMsg1Msg2 )
        
        @sagaManager.Handle( Msg1.new( "One" ) )
        @sagaManager.Handle( Msg2.new( "Two", "One" ) )
        @sagaManager.Handle( Msg1.new( "2" ) )
        @sagaManager.Handle( Msg2.new( "Two", "2" ) )
        
        #		assert_equal 2, @sagaManager.sagas["Msg2"][0]["data_list"].length
		assert_equal 2, @sagaManager.getDataListForSaga(DblSagaMsg1Msg2.name).length
	end

	def test_SagaWithTwoInstancesInterleaved
        @sagaManager = Saga_Manager_For_Testing.new
        @sagaManager.addSaga( DblSagaMsg1Msg2 )

        @sagaManager.Handle( Msg1.new( "One" ) )
		assert_equal 1, @sagaManager.getDataListForSaga(DblSagaMsg1Msg2.name).length
        @sagaManager.Handle( Msg1.new( "2" ) )
		assert_equal 2, @sagaManager.getDataListForSaga(DblSagaMsg1Msg2.name).length
        @sagaManager.Handle( Msg2.new( "Two", "One" ) )
        @sagaManager.Handle( Msg2.new( "Two", "2" ) )
		assert_equal 2, @sagaManager.getDataListForSaga(DblSagaMsg1Msg2.name).length
        
        
	end

end
