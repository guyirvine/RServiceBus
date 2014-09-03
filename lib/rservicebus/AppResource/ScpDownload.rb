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

    def delete( path, filepattern )
      RServiceBus.log "Host: #{@uri.host}, User: #{@uri.user}, File Pattern: #{filepattern}, Source: #{@uri.path}", true
      regexp = Regexp.new filepattern
      Net::SSH.start( @uri.host, @uri.user ) do |ssh|
        ssh.sftp.connect do |sftp|
          sftp.dir.foreach(path) do |entry|
            if entry.name =~ regexp then
              r = sftp.remove("#{path}/#{entry.name}")
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
