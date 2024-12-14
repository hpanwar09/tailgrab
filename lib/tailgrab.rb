# frozen_string_literal: true

require "date"

module Tailgrab
  class CLI
    DEFAULT_FILE = "#{Dir.home}/tailgrab.txt".freeze

    # rubocop:disable Metrics/MethodLength
    def self.parse(args)
      if args.empty?
        puts print_help
      elsif args[0] == "saved"
        saved(args)
      elsif args[0] == "delete"
        delete_file
      else
        n = args[0].to_i
        write_to_file(n)
        puts "Saved last #{n} commands in #{DEFAULT_FILE}" if n > 1
        puts "Saved last command in #{DEFAULT_FILE}" if n == 1
      end
    end
    # rubocop:enable Metrics/MethodLength

    # TODO : not working fix later
    def self.write_to_file(num)
      File.open(DEFAULT_FILE, "a+")

      # command = "history | grep -v 'history|tail|clear' | tail -n #{num} | awk '{print $2}'"
      command = "fc -l -#{num} | grep -v 'history|tail|clear' | awk '{print $2}'"
      `#{command} << #{DEFAULT_FILE}`

      # File.open(DEFAULT_FILE, "a+") do |file|
      #   file.puts `#{command}`
      # end
    end

    def self.read_from_file
      return puts "No saved commands" if blank_file?

      puts "Saved commands:"
      File.open(DEFAULT_FILE, "r") do |file|
        file.each_line do |line|
          puts line
        end
      end
    end

    def self.delete_file
      FileUtils.rm_f(DEFAULT_FILE)
      puts "Deleted saved commands"
    end

    # rubocop:disable Metrics/MethodLength
    def self.saved(args)
      case args[1]
      when "weekly"
        comm = []
        File.open(DEFAULT_FILE, "r") do |file|
          file.each_line do |line|
            saved_date = Date.parse(line.split.first)

            comm << line if saved_date > Date.today - 6
          end
        end

        if comm.any?
          puts "Weekly saved commands:"
          comm.each { |c| puts c }
        end
      else
        read_from_file
      end
    end
    # rubocop:enable Metrics/MethodLength

    def self.print_help
      "Usage: grab n
    Use to save last n terminal commands with timestamp.
    Keep a list of all the useful commands.\n
    Pass in 'saved' to show your saved commands.\n
    Examples:
    grab 5 - save last 5 commands\n
    grab saved - prints the saved commands\n"
    end

    def self.blank_file?
      !File.exist?(DEFAULT_FILE) || File.empty?(DEFAULT_FILE)
    end
  end
end
