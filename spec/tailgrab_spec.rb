# frozen_string_literal: true

RSpec.describe Tailgrab do
  it "has a version number" do
    expect(Tailgrab::VERSION).not_to be_nil
  end

  it "has a semver-style version" do
    expect(Tailgrab::VERSION).to match(/\A\d+\.\d+/)
  end
end
