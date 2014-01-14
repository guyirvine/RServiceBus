module RServiceBus


class Saga_Base
	attr_accessor :data

    def initialize
        @finished = false
    end

	def sendTimeout( msg, milliseconds )
	end

    def finish
        @data.finished = true
    end

end


end

