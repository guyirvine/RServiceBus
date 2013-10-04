module RServiceBus
    
    require 'parse-cron'
    
    class CronManager
        
        def initialize( host )
            @Bus = host
            
            @Bus.log "Load Cron", true
            @list = Array.new
            ENV.each do |k,v|
                if k.start_with?( "RSBCRON_" ) then
                    hash = Hash.new
					hash['name'] = k.sub( "RSBCRON_", "" )
					hash['last'] = Time.now
					hash['v'] = v
					hash['cron'] = CronParser.new(v)
					hash['next'] = hash['cron'].next(Time.now)
                    @list << hash
                    @Bus.log( "Cron set for, #{hash['name']}, #{v}" )
                    elsif k.start_with?( "RSBCRON" ) then
                    v.split( ";" ).each do |v|
                        parts = v.split( " ", 6 )
                        name = parts.pop
                        cron_string = parts.join( " " )
                        hash = Hash.new
                        hash['name'] = name
                        hash['last'] = Time.now
                        hash['v'] = cron_string
                        hash['cron'] = CronParser.new(cron_string)
                        hash['next'] = hash['cron'].next(Time.now)
                        @list << hash
                        @Bus.log( "Cron set for, #{hash['name']}, #{v}" )
                    end
                end
                
            end
        end
        
        def Run
            now = Time.now
            @list.map! do |v|
                if now > v['next'] then
                    @Bus.log "CronManager.Send, #{v['name']}", true
                    @Bus.Send( RServiceBus.createAnonymousClass( v['name'] ) )
                    v['next'] = v['cron'].next(now)
                end
                return v
            end
        end
        
    end
    
end

