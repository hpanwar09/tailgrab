# frozen_string_literal: true

require_relative "lib/tailgrab/version"

Gem::Specification.new do |spec|
  spec.name = "tailgrab"
  spec.version = Tailgrab::VERSION
  spec.authors = ["Himanshu Panwar"]
  spec.email = ["hpanwar@g2.com"]

  spec.summary = "Basic CLI to save your last n useful terminal commands in a text file"
  spec.description = "Save your last n useful terminal commands with timestamp and access them easily"
  spec.homepage = "https://github.com/hpanwar09/tailgrab"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/hpanwar09/tailgrab"
  spec.metadata["changelog_uri"] = "https://github.com/hpanwar09/tailgrab/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/console bin/setup test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.executables = ["grab"]
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
