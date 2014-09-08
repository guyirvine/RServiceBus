module RServiceBus

require 'rservicebus/SendAtStorage'

    class SendAtStorage

        def SendAtStorage.Get( uri )
            case uri.scheme
                when 'file'
                require 'rservicebus/SendAtStorage/File'
                return SendAtStorage_File.new( uri )
                when 'inmem'
                require 'rservicebus/SendAtStorage/InMemory'
                return SendAtStorage_InMemory.new( uri )
                else
                abort("Scheme, #{uri.scheme}, not recognised when configuring SendAtStorage, #{uri.to_s}");
            end

        end

    end

end

