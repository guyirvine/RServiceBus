module RServiceBus

    #Marshals configuration information for an rservicebus host
    class Config
        attr_reader :appName, :messageEndpointMappings, :handlerPathList, :sagaPathList, :errorQueueName, :maxRetries, :forwardReceivedMessagesTo, :subscriptionUri, :statOutputCountdown, :contractList, :libList, :forwardSentMessagesTo, :mqHost

        @appName
        @messageEndpointMappings
        @handlerPathList
        @sagaPathList
        @contractList

        @errorQueueName
        @forwardSentMessagesTo
        @maxRetries
        @forwardReceivedMessagesTo
        @subscriptionUri

        @mq

        def initialize()
            puts 'Cannot instantiate config directly.'
            puts 'For production, use ConfigFromEnv.'
            puts 'For debugging or testing, you could try ConfigFromSetter'
            abort()
        end

        def log( string )
            puts string
        end

        def getValue( name, default=nil )
            value = ( ENV[name].nil?  || ENV[name] == '') ? default : ENV[name];
            log "Env value: #{name}: #{value}"
            return value
        end

        #Marshals paths for message handlers
        #
        #Note. trailing slashs will be stripped
        #
        #Expected format;
        #	<path 1>;<path 2>
        def loadHandlerPathList()
            path = self.getValue( 'MSGHANDLERPATH', './MessageHandler')
            @handlerPathList = Array.new
            path.split(';').each do |path|
                path = path.strip.chomp('/')
                @handlerPathList << path
            end

            return self
        end

        def loadSagaPathList()
            path = self.getValue( 'SAGAPATH', './Saga')
            @sagaPathList = Array.new
            path.split(';').each do |path|
                path = path.strip.chomp('/')
                @sagaPathList << path
            end

            return self
        end

        def loadHostSection()
            @appName = self.getValue( 'APPNAME', 'RServiceBus')
            @errorQueueName = self.getValue( 'ERROR_QUEUE_NAME', 'error')
            @maxRetries = self.getValue( 'MAX_RETRIES', '5').to_i
            @statOutputCountdown = self.getValue( 'STAT_OUTPUT_COUNTDOWN', '100').to_i
            @subscriptionUri = self.getValue( 'SUBSCRIPTION_URI', "file:///tmp/#{appName}_subscriptions.yaml" )

            auditQueueName = self.getValue('AUDIT_QUEUE_NAME')
            if auditQueueName.nil? then
                @forwardSentMessagesTo = self.getValue('FORWARD_SENT_MESSAGES_TO')
                @forwardReceivedMessagesTo = self.getValue('FORWARD_RECEIVED_MESSAGES_TO')
                else
                @forwardSentMessagesTo = auditQueueName
                @forwardReceivedMessagesTo = auditQueueName
            end

            return self
        end

        def ensureContractFileExists( path )
            unless File.exists?(path) ||
                File.exists?("#{path}.rb") then
              puts 'Error while processing contracts'
              puts "*** path, #{path}, provided does not exist as a file"
              abort()
            end
            unless File.extname(path) == "" ||
                File.extname(path) == ".rb" then
              puts 'Error while processing contracts'
              puts "*** path, #{path}, should point to a ruby file, with extention .rb"
              abort()
            end
        end

        #Marshals paths for contracts
        #
        #Note. .rb extension is optional
        #
        #Expected format;
        #	/one/two/Contracts
        def loadContracts()
            @contractList = Array.new

            #This is a guard clause in case no Contracts have been specified
            #If any guard clauses have been specified, then execution should drop to the second block
            if self.getValue('CONTRACTS').nil? then
                return self
            end

            self.getValue( 'CONTRACTS', './Contract').split(';').each do |path|
                self.ensureContractFileExists( path )
                @contractList << path
            end
            return self
        end

        #Marshals paths for lib
        #
        #Note. .rb extension is optional
        #
        #Expected format;
        #	/one/two/Contracts
        def loadLibs()
            @libList = Array.new

            path = self.getValue('LIB')
            path = './lib' if path.nil? and File.exists?('./lib')
            if path.nil? then
                return self
            end

            path.split(';').each do |path|
                log "Loading libs from, #{path}"
                unless File.exists?(path) then
                  puts 'Error while processing libs'
                  puts "*** path, #{path}, should point to a ruby file, with extention .rb, or"
                  puts "*** path, #{path}, should point to a directory than conatins ruby files, that have extention .rb"
                  abort()
                end
                @libList << path
            end
            return self
        end

        def configureMq
            @mqHost = self.getValue( 'MQ', 'beanstalk://localhost')
            return self
        end

        #Marshals paths for working_dirs
        #
        #Note. trailing slashs will be stripped
        #
        #Expected format;
        #	<path 1>;<path 2>
        def loadWorkingDirList()
            pathList = self.getValue('WORKING_DIR')
            return self if pathList.nil?

            pathList.split(';').each do |path|

                path = path.strip.chomp('/')

                unless Dir.exists?("#{path}") then
                  puts 'Error while processing working directory list'
                  puts "*** path, #{path}, does not exist"
                  next
                end

                if Dir.exists?( "#{path}/MessageHandler" ) then
                    @handlerPathList << "#{path}/MessageHandler"
                end

                if Dir.exists?( "#{path}/Saga" ) then
                    @sagaPathList << "#{path}/Saga"
                end

                if File.exists?( "#{path}/Contract.rb" ) then
                    @contractList << "#{path}/Contract.rb"
                end

                if File.exists?( "#{path}/lib" ) then
                    @libList << "#{path}/lib"
                end
            end

            return self
        end

    end


    class ConfigFromEnv<Config

        def initialize()
        end

    end

    class ConfigFromSetter<Config
        attr_writer :appName, :messageEndpointMappings, :handlerPathList, :errorQueueName, :maxRetries, :forwardReceivedMessagesTo, :beanstalkHost

        def initialize()
        end

    end


end
