module RServiceBus
    
    require 'parse-cron'
    
    class Globber
        def self.parse_to_regex(str)
        escaped = Regexp.escape(str).gsub('\*','.*?')
        Regexp.new "^#{escaped}$", Regexp::IGNORECASE
    end
    
    def initialize(str)
        @regex = self.class.parse_to_regex str
    end
    
    def =~(str)
    !!(str =~ @regex)
end
end

class NoMatchingMsgForCron<StandardError
end

class CronManager
    
    
    def getMatchingMsgNames( name )
        list = Array.new
        @msgNames.each do |n|
            if Globber.new( name ) =~ n then
                list << n
            end
        end
        if list.length == 0 then
            raise NoMatchingMsgForCron.new( name )
        end

        return list
    end
    
    def addCron( name, cron_string )
        
        self.getMatchingMsgNames( name ).each do |n|
            hash = Hash.new
            hash['name'] = n
            hash['last'] = Time.now
            hash['v'] = cron_string
            hash['cron'] = CronParser.new(cron_string)
            hash['next'] = hash['cron'].next(Time.now)
            @list << hash
            @Bus.log( "Cron set for, #{n}, #{cron_string}, next run, #{hash['next']}" )
        end
    end
    
    def initialize( host, msgNames=Array.new )
        @Bus = host
        @msgNames = msgNames
        
        RServiceBus.rlog 'Load Cron'
        @list = Array.new
        ENV.each do |k,v|
            if k.start_with?('RSBCRON_') then
                self.addCron( k.sub( 'RSBCRON_', ''), v )
                elsif k.start_with?('RSBCRON') then
                v.split(';').each do |v|
                    parts = v.split( ' ', 6 )
                    
                    self.addCron( parts.pop, parts.join(' ') )
                end
            end
            
        end
    end
    
    def Run
        now = Time.now
        @list.each_with_index do |v,idx|
            if now > v['next'] then
                RServiceBus.rlog "CronManager.Send, #{v['name']}"
                @Bus.Send( RServiceBus.createAnonymousClass( v['name'] ) )
                @list[idx]['next'] = v['cron'].next(now)
            end
        end
    end
    
end

end

