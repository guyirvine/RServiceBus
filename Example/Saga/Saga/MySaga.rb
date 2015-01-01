
class Saga_MySaga<RServiceBus::Saga_Base
  attr_accessor :Bus

  def StartWith_Msg1(msg)
    @Bus.Send(Msg2.new(msg.name + ', 2'))
  end

  def Handle_Msg3(msg)
    @Bus.Send(Msg4.new(msg.name + ', 4'))
    self.Finish
  end
end
