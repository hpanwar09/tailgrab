# frozen_string_literal: true

module Tailgrab
  module Colors
    CODES = {
      reset: "\e[0m",
      bold: "\e[1m",
      dim: "\e[2m",
      cyan: "\e[36m"
    }.freeze

    module_function

    def enabled?
      $stdout.tty?
    end

    def cyan(text)
      wrap(text, :cyan)
    end

    def bold(text)
      wrap(text, :bold)
    end

    def dim(text)
      wrap(text, :dim)
    end

    def wrap(text, code)
      return text unless enabled?

      "#{CODES[code]}#{text}#{CODES[:reset]}"
    end
  end
end
