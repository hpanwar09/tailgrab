# frozen_string_literal: true

module Tailgrab
  class HistoryReader
    SUPPORTED_SHELLS = %i[zsh bash].freeze

    attr_reader :shell, :history_file

    def initialize(shell: nil, history_file: nil)
      @shell = shell || detect_shell
      @history_file = history_file || find_history_file
    end

    def last(count)
      return [] unless history_file && File.exist?(history_file)

      lines = read_last_lines(count)
      lines.map { |line| parse_line(line) }.compact
    end

    private

    def detect_shell
      shell_env = ENV["SHELL"] || ""
      if shell_env.include?("zsh")
        :zsh
      elsif shell_env.include?("bash")
        :bash
      else
        :unknown
      end
    end

    def find_history_file
      histfile = ENV.fetch("HISTFILE", nil)
      return File.expand_path(histfile) if histfile && !histfile.empty?

      case shell
      when :zsh
        File.expand_path("~/.zsh_history")
      when :bash
        File.expand_path("~/.bash_history")
      end
    end

    def read_last_lines(count)
      lines = File.readlines(history_file, chomp: true).reject(&:empty?)
      lines.last(count)
    end

    def parse_line(line)
      case shell
      when :zsh
        parse_zsh_line(line)
      else
        line.strip
      end
    end

    def parse_zsh_line(line)
      # Zsh extended history format: ": <timestamp>:0;<command>"
      match = line.match(/^: \d+:\d+;(.+)$/)
      match ? match[1].strip : line.strip
    end
  end
end
