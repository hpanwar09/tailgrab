# frozen_string_literal: true

require "tailgrab"
require "tmpdir"
require "fileutils"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around(:each, :uses_tmpdir) do |example|
    Dir.mktmpdir("tailgrab-test-") do |dir|
      @tmpdir = dir
      example.run
    end
  end
end
