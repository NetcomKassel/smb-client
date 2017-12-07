require 'time'

module SMB
  module ClientHelper
    class LsItem
      REGEX = /(?<name>[\.|\w]+)\s+(?<type>.)\s+(?<size>\d+)\s+(?<change_time>.+)/

      attr_accessor :name, :type, :size, :change_time

      def file?
        %w[A N].include? @type
      end

      def directory?
        %w[D].include? @type
      end

      def hidden?
        %w[H].include? @type
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
  end
end
