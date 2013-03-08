require 'rservicebus/Monitor/Dir'
require 'csv'

class Monitor_CsvPerLineDir<Monitor_Dir
    

    def ProcessFile( file )
        CSV.read( file ).each do |csvline|
            self.send( csvline )
        end
    end

end
