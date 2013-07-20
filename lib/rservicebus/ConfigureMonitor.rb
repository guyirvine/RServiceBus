module RServiceBus

    require 'rservicebus/Monitor'
    require 'rservicebus/Monitor/Message'

    #Configure AppResources for an rservicebus host
    class ConfigureMonitor
        
        @resourceList

        # Constructor
        #
        # @param [RServiceBus::Host] host instance
        # @param [Hash] appResources As hash[k,v] where k is the name of a resource, and v is the resource
        def initialize( host, appResources )
            @host = host
            @appResources = appResources
            
            @handlerList = Hash.new
            @resourceList = Hash.new
        end

        # Assigns appropriate resources to writable attributes in the handler that match keys in the resource hash
        #
        # @param [RServiceBus::Handler] handler
        ## @param [Hash] appResources As hash[k,v] where k is the name of a resource, and v is the resource
        def setAppResources( monitor )
            @host.log "Checking app resources for: #{monitor.class.name}", true
            @host.log "If your attribute is not getting set, check that it is in the 'attr_accessor' list", true
            @appResources.each do |k,v|
                if monitor.class.method_defined?( k ) then
                    monitor.instance_variable_set( "@#{k}", v.getResource() )
                    @resourceList[monitor.class.name] = Array.new if @resourceList[monitor.class.name].nil?
                    @resourceList[monitor.class.name] << v
                    @host.log "App resource attribute, #{k}, set for: " + monitor.class.name
                end
            end
            
            return self
        end


        def getMonitors( env )
            monitors = Array.new

            env.each do |k,v|
                if v.is_a?(String) and
					k.start_with?( "RSBOB_" ) then
                    uri = URI.parse( v )
                    name = k.sub( "RSBOB_", "" )
                    monitor = nil?
                    case uri.scheme
                        when "csvdir"
                        require "rservicebus/Monitor/CsvDir"
						monitor = Monitor_CsvDir.new( @host, name, uri )

                        when "xmldir"
                        require "rservicebus/Monitor/XmlDir"
						monitor = Monitor_XmlDir.new( @host, name, uri )

                        when "dir"
                        require "rservicebus/Monitor/Dir"
						monitor = Monitor_Dir.new( @host, name, uri )
                        
                        when "dirnotifier"
                        require "rservicebus/Monitor/DirNotifier"
						monitor = Monitor_DirNotifier.new( @host, name, uri )

                        when "csvperlinedir"
                        require "rservicebus/Monitor/CsvPerLine"
						monitor = Monitor_CsvPerLineDir.new( @host, name, uri )
                        else
						abort("Scheme, #{uri.scheme}, not recognised when configuring Monitor, #{k}=#{v}");
                    end
                    self.setAppResources( monitor )
                    monitors << monitor
                end
                
            end
            
            return monitors
        end
        
    end
    
end
