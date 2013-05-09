require 'rservicebus/Monitor/Dir'
require 'csv'

module RServiceBus
    
    class Monitor_CsvPerLineDir<Monitor_Dir
        
        def checkPayloadForNumberOfColumns( payload )
            if !@QueryStringParts.nil? && @QueryStringParts.has_key?("cols") then
                
                cols = @QueryStringParts["cols"][0].to_i
                payload.each_with_index do |row, idx|
                    if row.length != cols then
                        raise "Expected number of columns, #{cols}, Actual number of columns, #{row.length}, on line, #{idx}"
                    end
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
        
        
        def SendArray( payload, uri )
            payload.each do |csvline|
                self.send( csvline, uri )
            end
        end

        def SendHash( payload, uri )
            headLine = payload.shift
            payload.each do |csvline|
                hash = Hash.new
                csvline.each_with_index do |v,idx|
                    hash[headLine[idx]] = v
                end
                self.send( hash, uri )
            end
        end

        def ProcessPath( filePath )
            uri = URI.parse( "file://#{filePath}" )
            
            content = IO.read( filePath )
            payload = CSV.parse( content )
            
            
            self.checkPayloadForNumberOfColumns( payload )
            if self.checkSendHash then
                self.SendHash( payload, uri )
            else
                self.SendArray( payload, uri )
            end


            return content
        end
        
    end
    
end
