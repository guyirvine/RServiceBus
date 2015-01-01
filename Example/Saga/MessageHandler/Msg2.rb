
class MessageHandler_Msg2
  attr_accessor :Bus

  def Handle(msg)
    @Bus.Reply(Msg3.new(msg.name + ', 3'))
  end
end
