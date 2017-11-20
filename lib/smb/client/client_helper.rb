require 'time'
require 'tempfile'

require_relative 'ls_item'

module SMB
  # Helper methods to get simpler access to smbclient's capabilities
  module ClientHelper
    # List contents of a remote directory
    # @param [String] mask The matching mask
    # @param [Boolean] raise If set, an error will be raised. If set to
    # +false+, an empty array will be returned
    # @return [Array] List of +mask+ matching LsItems
    def ls(mask = '', raise = true)
      ls_items = []
      output = exec 'ls ' + mask
      output.lines.each do |line|
        ls_item = LsItem.from_line(line)
        ls_items << ls_item if ls_item
      end
      ls_items
    rescue Client::RuntimeError => e
      raise e if raise
      []
    end

    # +dir+ is an alias for +ls+
    alias dir ls

    # Creates a new directory on the server
    # @param [String] path The path to be created
    # @param [Boolean] raise raise Error or just return +false+
    # @return [Boolean] true on success
    def mkdir(path, raise = true)
      exec 'mkdir ' + path
      true
    rescue Client::RuntimeError => e
      raise e if raise
      false
    end

    # Removes a directory on the server
    # @param [String] path The path to be removed
    # @param [TrueClass/FalseClass] raise raise Error or just return +false+
    # @return [Boolean] true on success
    def rmdir(path, raise = true)
      exec 'rmdir ' + path
      true
    rescue Client::RuntimeError => e
      raise e if raise
      false
    end

    # Upload a local file
    # @param [String] from The source file path (on local machine)
    # @param [String] to The destination file path
    # @param [Boolean] overwrite Overwrite if exist on server?
    # @param [Boolean] raise raise Error or just return +false+
    # @return [Boolean] true on success
    def put(from, to, overwrite = false, raise = true)
      ls_items = ls to, false
      if !overwrite && !ls_items.empty?
        raise Client::RuntimeError, "File [#{to}] already exist"
      end
      exec 'put ' + from + ' ' + to
      true
    rescue Client::RuntimeError => e
      raise e if raise
      false
    end

    # Writes content to remote file
    # @param [String] content The content to be written
    # @param [String] to The destination file path
    # @param [Boolean] overwrite Overwrite if exist on server?
    # @param [Boolean] raise raise Error or just return +false+
    # @return [Boolean] true on success
    def write(content, to, overwrite = false, raise = true)
      # This is just a hack around +put+
      tempfile = Tempfile.new
      tempfile.write content
      tempfile.close

      put tempfile.path, to, overwrite, raise
    end

    # Delete a remote file
    # @param [String] path The remote file to be deleted
    # @param [Boolean] raise raise raise Error or just return +false+
    # @return [Boolean] true on success
    def del(path, raise = true)
      exec 'del ' + path
      true
    rescue Client::RuntimeError => e
      raise e if raise
      false
    end

    # +rm+ is an alias for +del+
    alias rm del

    # Receive a file from the smb server to local.
    # If +to+ was not passed, a tempfile will be generated.
    # @param [String] from The remote file to be read
    # @param [String] to local file path to be created
    # @param [Boolean] overwrite Overwrite if exist locally?
    # @param [Boolean] raise raise Error or just return +false+
    def get(from, to = nil, overwrite = false, raise = true)
      # Create a new tempfile but delete it
      # The tempfile.path should be free to use now
      tempfile = Tempfile.new
      to ||= tempfile.path
      tempfile.unlink

      if !overwrite && File.exist?(to)
        raise Client::RuntimeError, "File [#{to}] already exist locally"
      end
      exec 'get ' + from + ' ' + to
      to
    rescue Client::RuntimeError => e
      raise e if raise
      false
    end

    # Reads a remote file and return its content
    # @param [String] from The file to be read from server
    # @param [Boolean] overwrite Overwrite if exist locally?
    # @param [Boolean] raise raise Error or just return +false+
    # @return [String] The content of the remote file
    def read(from, overwrite = false, raise = true)
      tempfile = Tempfile.new
      to = tempfile.path
      tempfile.unlink
      get from, to, overwrite, raise
      File.read to
    end
  end
end
