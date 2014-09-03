require 'net/scp'
require 'net/sftp'

module RServiceBus

  class ScpDownloadHelper
    attr_reader :uri

    def initialize( uri )
      @uri = uri
    end

    def download( destination )
      RServiceBus.log "Host: #{@uri.host}, User: #{@uri.user}, Source: #{@uri.path}, Destination: #{destination}", true
      Net::SCP.start( @uri.host, @uri.user ) do |scp|
        scp.download( @uri.path, destination, :recursive => true )
      end
    end

    def close
    end

    def delete( filepattern )
      RServiceBus.log "Host: #{@uri.host}, User: #{@uri.user}, File Pattern: #{filepattern}, Source: #{@uri.path}", true
      regexp = Regexp.new filepattern unless filepattern.nil?

      Net::SSH.start( @uri.host, @uri.user ) do |ssh|
        ssh.sftp.connect do |sftp|
          sftp.dir.foreach(@uri.path) do |entry|
            next if entry.name == '.' || entry.name == '..'
            if filepattern.nil? || entry.name =~ regexp then
              puts "#{@uri.path}/#{entry.name}"
              r = sftp.remove("#{@uri.path}/#{entry.name}")
              r.wait
            end
          end
        end
      end
    end
  end

  class AppResource_ScpDownload<AppResource

    def connect(uri)
      return ScpDownloadHelper.new( uri )

      return inputDir;
    end

  end
end
