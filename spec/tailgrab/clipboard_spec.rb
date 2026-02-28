# frozen_string_literal: true

RSpec.describe Tailgrab::Clipboard do
  before do
    # Reset memoized clipboard command between tests
    described_class.instance_variable_set(:@clipboard_command, nil)
  end

  describe ".copy" do
    context "when pbcopy is available (macOS)" do
      before do
        allow(described_class).to receive(:clipboard_command).and_return("pbcopy")
      end

      it "copies text to clipboard and returns true" do
        io = instance_double(IO)
        allow(IO).to receive(:popen).with("pbcopy", "w").and_yield(io)
        allow(io).to receive(:write).with("hello world")

        expect(described_class.copy("hello world")).to be true
        expect(io).to have_received(:write).with("hello world")
      end
    end

    context "when xclip is available (Linux)" do
      before do
        allow(described_class).to receive(:clipboard_command).and_return("xclip -selection clipboard")
      end

      it "copies text via xclip and returns true" do
        io = instance_double(IO)
        allow(IO).to receive(:popen).with("xclip -selection clipboard", "w").and_yield(io)
        allow(io).to receive(:write).with("some command")

        expect(described_class.copy("some command")).to be true
      end
    end

    context "when no clipboard tool is available" do
      before do
        allow(described_class).to receive(:clipboard_command).and_return(nil)
      end

      it "returns false" do
        expect(described_class.copy("anything")).to be false
      end
    end

    context "when clipboard command raises an error" do
      before do
        allow(described_class).to receive(:clipboard_command).and_return("pbcopy")
        allow(IO).to receive(:popen).and_raise(Errno::ENOENT)
      end

      it "returns false" do
        expect(described_class.copy("anything")).to be false
      end
    end
  end

  describe ".available?" do
    it "returns true when a clipboard command exists" do
      allow(described_class).to receive(:clipboard_command).and_return("pbcopy")
      expect(described_class.available?).to be true
    end

    it "returns false when no clipboard command exists" do
      allow(described_class).to receive(:clipboard_command).and_return(nil)
      expect(described_class.available?).to be false
    end
  end

  describe "clipboard command detection" do
    it "prefers pbcopy on macOS" do
      allow(described_class).to receive(:command_exists?).with("pbcopy").and_return(true)

      expect(described_class.send(:detect_clipboard_command)).to eq("pbcopy")
    end

    it "falls back to wl-copy on Wayland" do
      allow(described_class).to receive(:command_exists?).with("pbcopy").and_return(false)
      allow(described_class).to receive(:command_exists?).with("wl-copy").and_return(true)

      expect(described_class.send(:detect_clipboard_command)).to eq("wl-copy")
    end

    it "falls back to xclip on X11" do
      allow(described_class).to receive(:command_exists?).with("pbcopy").and_return(false)
      allow(described_class).to receive(:command_exists?).with("wl-copy").and_return(false)
      allow(described_class).to receive(:command_exists?).with("xclip").and_return(true)

      expect(described_class.send(:detect_clipboard_command)).to eq("xclip -selection clipboard")
    end

    it "falls back to xsel" do
      allow(described_class).to receive(:command_exists?).with("pbcopy").and_return(false)
      allow(described_class).to receive(:command_exists?).with("wl-copy").and_return(false)
      allow(described_class).to receive(:command_exists?).with("xclip").and_return(false)
      allow(described_class).to receive(:command_exists?).with("xsel").and_return(true)

      expect(described_class.send(:detect_clipboard_command)).to eq("xsel --clipboard --input")
    end

    it "returns nil when nothing is available" do
      allow(described_class).to receive(:command_exists?).and_return(false)

      expect(described_class.send(:detect_clipboard_command)).to be_nil
    end
  end
end
