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

        def checkSendHash
            if !@QueryStringParts.nil? && @QueryStringParts.has_key?("hash") then
                flag = @QueryStringParts["hash"][0]
                return flag == "Y"
            end
            
            return false
        end


        def ProcessToHash( payload )
            headLine = payload.shift
            newPayload = Array.new
            payload.each do |csvline|
                hash = Hash.new
                csvline.each_with_index do |v,idx|
                    hash[headLine[idx]] = v
                end
                newPayload << hash
            end
            
            return newPayload
        end
        
        def ProcessContent( content )
            payload = CSV.parse( content )
            self.checkPayloadForNumberOfColumns( payload )
            
            if self.checkSendHash then
                payload = self.ProcessToHash( payload )
            end

            return payload
        end
        
    end
    
end