require 'rservicebus/Monitor/Dir'
require 'xmlsimple'

class Monitor_XmlDir<Monitor_Dir


    def ProcessContent( content )
        return XmlSimple.xml_in( content )
    end

end
