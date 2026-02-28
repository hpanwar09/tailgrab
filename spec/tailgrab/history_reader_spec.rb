# frozen_string_literal: true

RSpec.describe Tailgrab::HistoryReader, :uses_tmpdir do
  describe "#detect_shell" do
    it "detects zsh" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SHELL").and_return("/bin/zsh")
      allow(ENV).to receive(:[]).with("HISTFILE").and_return(nil)

      reader = described_class.new
      expect(reader.shell).to eq(:zsh)
    end

    it "detects bash" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SHELL").and_return("/bin/bash")
      allow(ENV).to receive(:[]).with("HISTFILE").and_return(nil)

      reader = described_class.new
      expect(reader.shell).to eq(:bash)
    end

    it "returns :unknown for unsupported shells" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SHELL").and_return("/bin/fish")
      allow(ENV).to receive(:[]).with("HISTFILE").and_return(nil)

      reader = described_class.new
      expect(reader.shell).to eq(:unknown)
    end

    it "returns :unknown when SHELL is not set" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SHELL").and_return(nil)
      allow(ENV).to receive(:[]).with("HISTFILE").and_return(nil)

      reader = described_class.new
      expect(reader.shell).to eq(:unknown)
    end
  end

  describe "#history_file" do
    it "uses HISTFILE when set" do
      custom_path = File.join(@tmpdir, "custom_history")
      reader = described_class.new(history_file: custom_path)
      expect(reader.history_file).to eq(custom_path)
    end

    it "defaults to ~/.zsh_history for zsh" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("HISTFILE").and_return(nil)

      reader = described_class.new(shell: :zsh)
      expect(reader.history_file).to eq(File.expand_path("~/.zsh_history"))
    end

    it "defaults to ~/.bash_history for bash" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("HISTFILE").and_return(nil)

      reader = described_class.new(shell: :bash)
      expect(reader.history_file).to eq(File.expand_path("~/.bash_history"))
    end

    it "returns nil for unknown shell without HISTFILE" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("HISTFILE").and_return(nil)

      reader = described_class.new(shell: :unknown)
      expect(reader.history_file).to be_nil
    end
  end

  describe "#last" do
    context "with zsh history" do
      let(:history_file) { File.join(@tmpdir, ".zsh_history") }
      let(:reader) { described_class.new(shell: :zsh, history_file: history_file) }

      it "parses zsh extended history format" do
        File.write(history_file, <<~HIST)
          : 1772198246:0;git status
          : 1772198300:0;ls -la
          : 1772198400:0;bundle exec rake
        HIST

        result = reader.last(2)
        expect(result).to eq(["ls -la", "bundle exec rake"])
      end

      it "handles commands with semicolons" do
        File.write(history_file, ": 1772198246:0;cd /tmp && ls; echo done\n")

        result = reader.last(1)
        expect(result).to eq(["cd /tmp && ls; echo done"])
      end

      it "handles malformed lines gracefully" do
        File.write(history_file, <<~HIST)
          some random text
          : 1772198246:0;git status
        HIST

        result = reader.last(2)
        expect(result).to eq(["some random text", "git status"])
      end
    end

    context "with bash history" do
      let(:history_file) { File.join(@tmpdir, ".bash_history") }
      let(:reader) { described_class.new(shell: :bash, history_file: history_file) }

      it "reads plain command lines" do
        File.write(history_file, <<~HIST)
          git status
          ls -la
          docker ps
        HIST

        result = reader.last(2)
        expect(result).to eq(["ls -la", "docker ps"])
      end

      it "skips blank lines" do
        File.write(history_file, "git status\n\n\nls -la\n")

        result = reader.last(5)
        expect(result).to eq(["git status", "ls -la"])
      end
    end

    it "returns empty array when history file does not exist" do
      reader = described_class.new(shell: :zsh, history_file: "/nonexistent/path")
      expect(reader.last(5)).to eq([])
    end

    it "returns empty array when history_file is nil" do
      reader = described_class.new(shell: :unknown, history_file: nil)
      expect(reader.last(5)).to eq([])
    end

    it "returns all entries when N exceeds history size" do
      history_file = File.join(@tmpdir, ".zsh_history")
      File.write(history_file, ": 1772198246:0;only one\n")

      reader = described_class.new(shell: :zsh, history_file: history_file)
      result = reader.last(100)
      expect(result).to eq(["only one"])
    end
  end
end
