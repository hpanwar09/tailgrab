# frozen_string_literal: true

RSpec.describe Tailgrab::Storage, :uses_tmpdir do
  subject(:storage) { described_class.new(file_path: file_path) }

  let(:file_path) { File.join(@tmpdir, "tailgrab.txt") }

  describe "#save" do
    it "creates the file and writes commands with timestamps" do
      freeze_time = Time.new(2026, 2, 28, 14, 30, 0)
      allow(Time).to receive(:now).and_return(freeze_time)

      storage.save(["git status", "ls -la"])

      content = File.read(file_path)
      expect(content).to include("2026-02-28 14:30:00 | git status")
      expect(content).to include("2026-02-28 14:30:00 | ls -la")
    end

    it "appends to an existing file" do
      File.write(file_path, "2026-02-27 10:00:00 | old command\n")

      freeze_time = Time.new(2026, 2, 28, 12, 0, 0)
      allow(Time).to receive(:now).and_return(freeze_time)

      storage.save(["new command"])

      lines = File.readlines(file_path, chomp: true)
      expect(lines.length).to eq(2)
      expect(lines.first).to eq("2026-02-27 10:00:00 | old command")
      expect(lines.last).to eq("2026-02-28 12:00:00 | new command")
    end

    it "handles commands with special characters" do
      freeze_time = Time.new(2026, 1, 1, 0, 0, 0)
      allow(Time).to receive(:now).and_return(freeze_time)

      storage.save(['echo "hello | world"', "grep -E 'foo|bar' file.txt"])

      content = File.read(file_path)
      expect(content).to include('echo "hello | world"')
      expect(content).to include("grep -E 'foo|bar' file.txt")
    end
  end

  describe "#read_last" do
    it "returns the last N entries" do
      File.write(file_path, <<~FILE)
        2026-02-28 10:00:00 | cmd1
        2026-02-28 11:00:00 | cmd2
        2026-02-28 12:00:00 | cmd3
        2026-02-28 13:00:00 | cmd4
      FILE

      result = storage.read_last(2)
      expect(result).to eq(["2026-02-28 12:00:00 | cmd3", "2026-02-28 13:00:00 | cmd4"])
    end

    it "returns all entries when N exceeds total" do
      File.write(file_path, <<~FILE)
        2026-02-28 10:00:00 | cmd1
        2026-02-28 11:00:00 | cmd2
      FILE

      result = storage.read_last(100)
      expect(result.length).to eq(2)
    end

    it "returns empty array when file does not exist" do
      expect(storage.read_last(5)).to eq([])
    end

    it "returns empty array when file is empty" do
      File.write(file_path, "")
      expect(storage.read_last(5)).to eq([])
    end

    it "skips blank lines" do
      File.write(file_path, "2026-02-28 10:00:00 | cmd1\n\n\n2026-02-28 11:00:00 | cmd2\n")

      result = storage.read_last(5)
      expect(result.length).to eq(2)
    end
  end

  describe "#read_since" do
    it "returns entries since a given time" do
      File.write(file_path, <<~FILE)
        2026-02-26 10:00:00 | old
        2026-02-27 10:00:00 | yesterday
        2026-02-28 10:00:00 | today
      FILE

      result = storage.read_since(Time.new(2026, 2, 27, 0, 0, 0))
      expect(result.length).to eq(2)
      expect(result.first).to include("yesterday")
      expect(result.last).to include("today")
    end

    it "returns empty array when nothing matches" do
      File.write(file_path, "2026-01-01 10:00:00 | ancient\n")

      result = storage.read_since(Time.new(2026, 12, 1))
      expect(result).to eq([])
    end

    it "returns empty array when file does not exist" do
      expect(storage.read_since(Time.now - 86_400)).to eq([])
    end

    it "handles entries with malformed timestamps gracefully" do
      File.write(file_path, <<~FILE)
        not-a-timestamp | broken
        2026-02-28 10:00:00 | valid
      FILE

      result = storage.read_since(Time.new(2026, 2, 28, 0, 0, 0))
      expect(result).to eq(["2026-02-28 10:00:00 | valid"])
    end
  end

  describe "#wipe" do
    it "empties the file" do
      File.write(file_path, "2026-02-28 10:00:00 | something\n")

      storage.wipe

      expect(File.exist?(file_path)).to be true
      expect(File.empty?(file_path)).to be true
    end

    it "creates an empty file if none exists" do
      storage.wipe

      expect(File.exist?(file_path)).to be true
      expect(File.empty?(file_path)).to be true
    end
  end

  describe "#read_all" do
    it "returns all entries" do
      File.write(file_path, <<~FILE)
        2026-02-28 10:00:00 | cmd1
        2026-02-28 11:00:00 | cmd2
        2026-02-28 12:00:00 | cmd3
      FILE

      result = storage.read_all
      expect(result.length).to eq(3)
    end

    it "returns empty array when file does not exist" do
      expect(storage.read_all).to eq([])
    end

    it "returns empty array when file is empty" do
      File.write(file_path, "")
      expect(storage.read_all).to eq([])
    end
  end

  describe "#content?" do
    it "returns true when file has content" do
      File.write(file_path, "2026-02-28 10:00:00 | something\n")
      expect(storage.content?).to be true
    end

    it "returns false when file is empty" do
      File.write(file_path, "")
      expect(storage.content?).to be false
    end

    it "returns false when file does not exist" do
      expect(storage.content?).to be false
    end
  end

  describe "#extract_command" do
    it "strips the timestamp prefix" do
      expect(storage.extract_command("2026-02-28 10:00:00 | git status")).to eq("git status")
    end

    it "returns the full string if format does not match" do
      expect(storage.extract_command("random text")).to eq("random text")
    end

    it "handles commands containing pipe characters" do
      entry = "2026-02-28 10:00:00 | cat file | grep foo"
      expect(storage.extract_command(entry)).to eq("cat file | grep foo")
    end
  end
end
