require 'rservicebus/Monitor/Dir'
require 'csv'

class Monitor_CsvPerLineDir<Monitor_Dir
    

    def ProcessPath( filePath )
        uri = URI.parse( "file://#{filePath}" )
        
        content = IO.read( filePath )
        CSV.parse( content ).each do |csvline|
            self.send( csvline, uri )
        end
        
        return content
    end

end
