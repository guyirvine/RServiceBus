
class MessageHandler_HelloWorld

	attr_accessor :Bus, :State

	def Handle( msg )
#raise "Manually generated error for testng"
		count = @State['count'] || 0
		count = count + 1
		puts "count: #{count}"
		@State['count'] = count
		puts 'Handling Msg'
	end
end


