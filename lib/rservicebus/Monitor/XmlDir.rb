require 'rservicebus/Monitor/Dir'
require 'xmlsimple'

class Monitor_XmlDir<Monitor_Dir


    def ProcessPath( path )
        #        return Nokogiri::XML( File.open(path) )
        return XmlSimple.xml_in( path )
    end

end
