# == DownloadManager
#
# The DownloadManager provides a way of downloading files.
module AutomateIt
  class DownloadManager < Plugin::Manager
    alias_methods :download

    # Downloads the +source+ document.
    #
    # Options:
    # * :to -- Saves source to this filename or directory. Defaults to current directory.
    def download(*arguments) dispatch(*arguments) end

    # == DownloadManager::BaseDriver
    #
    # Base class for all DownloadManager drivers.
    class BaseDriver < Plugin::Driver
    end

    # == DownloadManager::OpenURI
    #
    # A DownloadManager driver using the OpenURI module for handling HTTP and FTP transfers.
    class OpenURI < BaseDriver
      depends_on :libraries => %w(open-uri)

      def suitability(method, *args) # :nodoc:
        return available? ? 1 : 0
      end

      # See DownloadManager#download
      def download(*arguments)
        args, opts = args_and_opts(*arguments)
        source = args[0] or raise ArgumentError.new("No source specified")
        target = args[1] || opts[:to] || File.basename(source)
        target = File.join(target, File.basename(source)) if File.directory?(target)
        log.info(PNOTE+"Downloading #{target}")
        if writing?
          open(target, "w+") do |writer|
            open(source) do |reader|
              writer.write(reader.read)
            end
          end
        end
        return writing?
      end
    end
  end
end
