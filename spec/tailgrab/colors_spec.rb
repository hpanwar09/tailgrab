# frozen_string_literal: true

RSpec.describe Tailgrab::Colors do
  describe ".enabled?" do
    it "returns false when stdout is not a TTY" do
      allow($stdout).to receive(:tty?).and_return(false)
      expect(described_class.enabled?).to be false
    end

    it "returns true when stdout is a TTY" do
      allow($stdout).to receive(:tty?).and_return(true)
      expect(described_class.enabled?).to be true
    end
  end

  context "when colors are enabled" do
    before { allow($stdout).to receive(:tty?).and_return(true) }

    describe ".cyan" do
      it "wraps text with cyan ANSI code" do
        expect(described_class.cyan("hello")).to eq("\e[36mhello\e[0m")
      end
    end

    describe ".bold" do
      it "wraps text with bold ANSI code" do
        expect(described_class.bold("hello")).to eq("\e[1mhello\e[0m")
      end
    end

    describe ".dim" do
      it "wraps text with dim ANSI code" do
        expect(described_class.dim("hello")).to eq("\e[2mhello\e[0m")
      end
    end
  end

  context "when colors are disabled (not a TTY)" do
    before { allow($stdout).to receive(:tty?).and_return(false) }

    it "returns plain text for all methods" do
      expect(described_class.cyan("hello")).to eq("hello")
      expect(described_class.bold("hello")).to eq("hello")
      expect(described_class.dim("hello")).to eq("hello")
    end
  end
end
