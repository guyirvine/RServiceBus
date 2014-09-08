module RServiceBus

class Audit

    def initialize( mq )
        @mq = mq
        auditQueueName = RServiceBus.getValue('AUDIT_QUEUE_NAME')
        if auditQueueName.nil? then
                @forwardSentMessagesTo = RServiceBus.getValue('FORWARD_SENT_MESSAGES_TO')
                @forwardReceivedMessagesTo = RServiceBus.getValue('FORWARD_RECEIVED_MESSAGES_TO')
            else
                @forwardSentMessagesTo = auditQueueName
                @forwardReceivedMessagesTo = auditQueueName
        end
    end

    def auditToQueue( obj )
        @mq.sendMsg(obj, @forwardSentMessagesTo)
    end

    def auditOutgoing( obj )
      unless @forwardSentMessagesTo.nil? then
        self.auditToQueue(obj)
      end
    end
    def auditIncoming( obj )
      unless @forwardReceivedMessagesTo.nil? then
        self.auditToQueue(obj)
      end
    end


end

end
