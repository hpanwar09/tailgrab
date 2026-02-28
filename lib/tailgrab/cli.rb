# frozen_string_literal: true

module Tailgrab
  class CLI
    COMMANDS = %w[help last all day wipe].freeze
    HELP_TEXT = <<~HELP
      Tailgrab — Save and recall your terminal commands

      Usage:
        grab N          Save last N commands from shell history
        grab last       Copy last saved command to clipboard
        grab last N     Show last N saved commands (N=1 copies to clipboard)
        grab all        Show all saved commands
        grab day        Show commands saved in the last 24 hours
        grab wipe       Clear all saved commands
        grab help       Show this help message

      Examples:
        grab 5          Save your last 5 terminal commands
        grab last 3     Show the 3 most recently saved commands
        grab last       Copy the most recent saved command to clipboard

      Tip: Add 'setopt INC_APPEND_HISTORY' to ~/.zshrc so commands from
      all open terminals are available immediately.

      File: ~/tailgrab.txt
    HELP

    def initialize(args, storage: Storage.new, history_reader: HistoryReader.new)
      @args = args
      @storage = storage
      @history_reader = history_reader
    end

    def run
      command = @args[0]

      if command.nil? || command == "help"
        print_help
      elsif COMMANDS.include?(command)
        send("handle_#{command}")
      elsif command.match?(/\A\d+\z/)
        handle_save(command.to_i)
      else
        puts "Unknown command: #{command}\n\n"
        print_help
      end
    end

    private

    def handle_save(count)
      return puts("Please provide a positive number.") if count < 1

      commands = @history_reader.last(count)
      return puts("No shell history found. Is your history file accessible?") if commands.empty?

      @storage.save(commands)
      noun = commands.length == 1 ? "command" : "commands"
      puts "Saved #{commands.length} #{noun} to #{@storage.file_path}"
    end

    def handle_last
      count = parse_last_count
      return if count.nil?

      entries = @storage.read_last(count)
      return puts("No saved commands yet. Run 'grab N' to save some.") if entries.empty?

      count == 1 ? copy_to_clipboard(entries.last) : print_entries("Last #{entries.length} saved commands:", entries)
    end

    def handle_day
      entries = @storage.read_since(Time.now - 86_400)
      return puts("No commands saved in the last 24 hours.") if entries.empty?

      print_entries("Commands saved in the last 24 hours:", entries)
    end

    def handle_all
      entries = @storage.read_all
      return puts("No saved commands yet. Run 'grab N' to save some.") if entries.empty?

      print_entries("All saved commands (#{entries.length}):", entries)
    end

    def handle_wipe
      @storage.wipe
      puts "All saved commands have been cleared."
    end

    def parse_last_count
      raw = @args[1]
      return 1 if raw.nil?
      return puts("Invalid number: #{raw}") unless raw.match?(/\A\d+\z/)

      count = raw.to_i
      return puts("Please provide a positive number.") if count < 1

      count
    end

    def copy_to_clipboard(entry)
      command = @storage.extract_command(entry)
      if Clipboard.copy(command)
        puts "Copied to clipboard: #{command}"
      else
        puts command
        puts "(clipboard not available — install pbcopy, xclip, or xsel)"
      end
    end

    def print_entries(header, entries)
      puts header
      entries.each_with_index do |entry, idx|
        puts "  #{Colors.cyan("#{idx + 1}.")} #{format_entry(entry)}"
      end
    end

    def format_entry(entry)
      match = entry.match(Storage::ENTRY_PATTERN)
      return entry unless match

      "#{Colors.dim(match[1])} #{Colors.dim("|")} #{Colors.bold(match[2])}"
    end

    def print_help
      puts HELP_TEXT
    end
  end
end
