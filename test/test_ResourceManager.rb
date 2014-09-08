require 'test/unit'
require './lib/rservicebus/SagaStorage.rb'
require './lib/rservicebus/StateManager.rb'
require './lib/rservicebus/AppResource.rb'

require './lib/rservicebus/ResourceManager.rb'


class Test_ResourceManager<RServiceBus::ResourceManager
    
end

class Test_Resource
    attr_reader :string, :close_called, :commit_called, :rollback_called
    
    def initialize( string )
        @string = string
        @close_called = false
        @commit_called = false
    end
    
    def close
        @close_called = true
    end
    
    def Commit
        @commit_called = true
    end
    
    def Rollback
        @rollback_called = true
    end
    
end

class Test_AppResource<RServiceBus::AppResource
    attr_reader :r
    
    def connect(uri)
        @r = Test_Resource.new( uri )
        return @r
    end
    
    def Commit
        @r.Commit
    end
    
    def Rollback
        @r.Rollback
    end
    
end


class ResourceManagerTest < Test::Unit::TestCase
    
    def setup
        ENV['SAGA_URI'] = 'immem://'
        @sa = RServiceBus::SagaStorage.Get( URI.parse('inmem://path') )
        
        ENV['STATE_URI'] = 'immem://'
        @st = RServiceBus::StateManager.new
        @r = RServiceBus::ResourceManager.new( @st, @sa )
    end
    
	def test_GetAll
        
        @r.add( 'one', 'one')
        @r.add( 'two', 'two')
        
        assert_equal Hash['one', 'one', 'two', 'two'], @r.getAll
        
    end
    
    def test_Get
        ta_before = Test_AppResource.new( nil, nil )
        
        @r.add( 'test', ta_before )
        
        ta_after = @r.get('test')
        assert_equal 'Test_AppResource', ta_after.class.name
        
    end
    
    def test_Commit
        ta_before = Test_AppResource.new( nil, nil )
        
        @r.add( 'test', ta_before )
        
        @r.Begin
        ta_after = @r.get('test')
        tr = ta_after.r
        assert_equal 'Test_Resource', tr.class.name
        assert_equal false, tr.commit_called
        
        @r.Commit('MsgName')
        assert_equal 'Test_AppResource', ta_after.class.name
        assert_equal true, tr.commit_called
        
    end
    
    def test_Rollback
        ta_before = Test_AppResource.new( nil, nil )
        
        @r.add( 'test', ta_before )
        
        @r.Begin
        ta_after = @r.get('test')
        tr = ta_after.r
        assert_equal 'Test_Resource', tr.class.name
        assert_equal false, tr.commit_called
        
        @r.Rollback('MsgName')
        assert_equal 'Test_AppResource', ta_after.class.name
        assert_equal false, tr.commit_called
        assert_equal true, tr.rollback_called
        
    end
    
end
