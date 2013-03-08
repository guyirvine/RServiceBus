require 'rservicebus/Monitor/Dir'
require 'csv'

class Monitor_CsvDir<Monitor_Dir
    

    def ProcessPath( path )
        return CSV.read( path )
    end

end
