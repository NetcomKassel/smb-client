require 'time'
require 'tempfile'

module SMB
  module ClientHelper
    class LsItem
      REGEX = /(?<name>[\.|\w]+)\s+(?<type>.)\s+(?<size>\d+)\s+(?<change_time>.+)/

      attr_accessor :name, :type, :size, :change_time

      def file?
        @type.include? 'N'
      end

      def directory?
        @type.include? 'D'
      end

      def hidden?
        @type.include? 'H'
      end

      def self.from_line(line)
        match_data = REGEX.match line
        return nil unless match_data

        item = LsItem.new
        item.name = match_data['name']
        item.type = match_data['type']
        item.size = match_data['size'].to_i
        item.change_time = Time.parse match_data['change_time']
        item
      end
    end

    def ls(mask = '', raise = true)
      ls_items = []
      output = exec 'ls ' + mask
      output.lines do |line|
        ls_item = LsItem.from_line(line)
        ls_items << ls_item if ls_item
      end
      ls_items
    rescue Client::RuntimeError => e
      raise e if raise
      []
    end

    alias dir ls

    def mkdir(path, raise = true)
      exec 'mkdir ' + path
      true
    rescue Client::RuntimeError => e
      raise e if raise
      false
    end

    def rmdir(path, raise = true)
      exec 'rmdir ' + path
      true
    rescue Client::RuntimeError => e
      raise e if raise
      false
    end

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

    def write(content, to, overwrite = false, raise = true)
      tempfile = Tempfile.new
      tempfile.write content
      tempfile.close

      put tempfile.path, to, overwrite, raise
    end

    def del(path, raise = true)
      exec 'del ' + path
      true
    rescue Client::RuntimeError => e
      raise e if raise
      false
    end

    alias rm del

    def get(from, to = nil, overwrite = false, raise = true)
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
  end
end
