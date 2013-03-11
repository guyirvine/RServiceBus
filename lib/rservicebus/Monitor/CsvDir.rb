require 'rservicebus/Monitor/Dir'
require 'csv'

module RServiceBus
    
    class Monitor_CsvDir<Monitor_Dir
        
        
        def checkPayloadForNumberOfColumns( payload )
            return if @QueryStringParts.nil?
            return unless @QueryStringParts.has_key?("cols")
            
            cols = @QueryStringParts["cols"][0].to_i
            payload.each_with_index do |row, idx|
                if row.length != cols then
                    raise "Expected number of columns, #{cols}, Actual number of columns, #{row.length}, on line, #{idx}"
                end
            end
            
        end
        
        def ProcessContent( content )
            payload = CSV.parse( content )
            self.checkPayloadForNumberOfColumns( payload )
            return payload
        end
        
    end
    
end