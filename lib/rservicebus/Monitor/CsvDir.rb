require 'rservicebus/Monitor/Dir'
require 'csv'

class Monitor_CsvDir<Monitor_Dir
    

    def ProcessContent( content )
        return CSV.parse( content )
    end

end
