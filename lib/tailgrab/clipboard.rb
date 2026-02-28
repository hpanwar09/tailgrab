# frozen_string_literal: true

module Tailgrab
  class Clipboard
    class << self
      def copy(text)
        cmd = clipboard_command
        return false unless cmd

        IO.popen(cmd, "w") { |io| io.write(text) }
        true
      rescue Errno::ENOENT, IOError
        false
      end

      def available?
        !clipboard_command.nil?
      end

      private

      def clipboard_command
        @clipboard_command ||= detect_clipboard_command
      end

      def detect_clipboard_command
        if command_exists?("pbcopy")
          "pbcopy"
        elsif command_exists?("wl-copy")
          "wl-copy"
        elsif command_exists?("xclip")
          "xclip -selection clipboard"
        elsif command_exists?("xsel")
          "xsel --clipboard --input"
        end
      end

      def command_exists?(cmd)
        system("which #{cmd} > /dev/null 2>&1")
      end
    end
  end
end
