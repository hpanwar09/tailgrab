# frozen_string_literal: true

require "time"

module Tailgrab
  class Storage
    DEFAULT_FILE = File.join(Dir.home, "tailgrab.txt").freeze
    TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S"
    ENTRY_PATTERN = /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \| (.+)$/

    attr_reader :file_path

    def initialize(file_path: DEFAULT_FILE)
      @file_path = file_path
    end

    def save(commands)
      timestamp = Time.now.strftime(TIMESTAMP_FORMAT)

      File.open(file_path, "a") do |f|
        commands.each do |cmd|
          f.puts "#{timestamp} | #{cmd}"
        end
      end
    end

    def read_last(count)
      return [] unless content?

      entries = all_entries
      entries.last(count)
    end

    def read_since(since_time)
      return [] unless content?

      all_entries.select do |entry|
        ts = parse_timestamp(entry)
        ts && ts >= since_time
      end
    end

    def wipe
      File.write(file_path, "")
    end

    def content?
      File.exist?(file_path) && !File.empty?(file_path)
    end

    def extract_command(entry)
      match = entry.match(ENTRY_PATTERN)
      match ? match[2] : entry
    end

    def read_all
      return [] unless content?

      all_entries
    end

    private

    def all_entries
      File.readlines(file_path, chomp: true).reject(&:empty?)
    end

    def parse_timestamp(entry)
      match = entry.match(ENTRY_PATTERN)
      return nil unless match

      Time.parse(match[1])
    rescue ArgumentError
      nil
    end
  end
end
