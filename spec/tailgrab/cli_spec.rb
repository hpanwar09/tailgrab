# frozen_string_literal: true

RSpec.describe Tailgrab::CLI, :uses_tmpdir do
  let(:storage_file) { File.join(@tmpdir, "tailgrab.txt") }
  let(:history_file) { File.join(@tmpdir, ".zsh_history") }
  let(:storage) { Tailgrab::Storage.new(file_path: storage_file) }
  let(:history_reader) { Tailgrab::HistoryReader.new(shell: :zsh, history_file: history_file) }

  def run_cli(*args)
    cli = described_class.new(args, storage: storage, history_reader: history_reader)
    cli.run
  end

  def seed_history(*commands)
    content = commands.each_with_index.map do |cmd, i|
      ": #{1_700_000_000 + i}:0;#{cmd}"
    end
    File.write(history_file, "#{content.join("\n")}\n")
  end

  def seed_storage(*entries)
    content = entries.map { |e| "#{e}\n" }.join
    File.write(storage_file, content)
  end

  describe "grab (no args) / grab help" do
    it "prints help when no args given" do
      output = capture_output { run_cli }
      expect(output).to include("Tailgrab")
      expect(output).to include("grab N")
      expect(output).to include("grab last")
      expect(output).to include("grab day")
      expect(output).to include("grab wipe")
      expect(output).to include("grab help")
      expect(output).to include("grab all")
    end

    it "prints help for 'help' command" do
      output = capture_output { run_cli("help") }
      expect(output).to include("Tailgrab")
      expect(output).to include("Usage:")
    end
  end

  describe "grab N (save commands)" do
    it "saves last N commands from shell history" do
      seed_history("git status", "ls -la", "bundle exec rake", "docker ps")

      output = capture_output { run_cli("3") }

      expect(output).to include("Saved 3 commands")
      expect(File.exist?(storage_file)).to be true

      content = File.read(storage_file)
      expect(content).to include("ls -la")
      expect(content).to include("bundle exec rake")
      expect(content).to include("docker ps")
      expect(content).not_to include("git status")
    end

    it "saves single command with singular message" do
      seed_history("git status")

      output = capture_output { run_cli("1") }
      expect(output).to include("Saved 1 command to")
      expect(output).not_to include("commands")
    end

    it "appends to existing file" do
      seed_storage("2026-02-27 10:00:00 | old command")
      seed_history("new command")

      capture_output { run_cli("1") }

      lines = File.readlines(storage_file, chomp: true).reject(&:empty?)
      expect(lines.length).to eq(2)
      expect(lines.first).to include("old command")
      expect(lines.last).to include("new command")
    end

    it "rejects zero" do
      output = capture_output { run_cli("0") }
      expect(output).to include("positive number")
    end

    it "shows error when history is empty" do
      File.write(history_file, "")

      output = capture_output { run_cli("5") }
      expect(output).to include("No shell history found")
    end

    it "shows error when history file does not exist" do
      output = capture_output { run_cli("5") }
      expect(output).to include("No shell history found")
    end
  end

  describe "grab last / grab last N" do
    it "copies last command to clipboard when no number given" do
      seed_storage("2026-02-28 10:00:00 | git status")
      allow(Tailgrab::Clipboard).to receive(:copy).and_return(true)

      output = capture_output { run_cli("last") }

      expect(Tailgrab::Clipboard).to have_received(:copy).with("git status")
      expect(output).to include("Copied to clipboard: git status")
    end

    it "copies last command to clipboard when N is 1" do
      seed_storage(
        "2026-02-28 10:00:00 | first",
        "2026-02-28 11:00:00 | second"
      )
      allow(Tailgrab::Clipboard).to receive(:copy).and_return(true)

      output = capture_output { run_cli("last", "1") }

      expect(Tailgrab::Clipboard).to have_received(:copy).with("second")
      expect(output).to include("Copied to clipboard: second")
    end

    it "prints command when clipboard is not available" do
      seed_storage("2026-02-28 10:00:00 | git push")
      allow(Tailgrab::Clipboard).to receive(:copy).and_return(false)

      output = capture_output { run_cli("last") }

      expect(output).to include("git push")
      expect(output).to include("clipboard not available")
    end

    it "prints last N commands when N > 1" do
      seed_storage(
        "2026-02-28 10:00:00 | cmd1",
        "2026-02-28 11:00:00 | cmd2",
        "2026-02-28 12:00:00 | cmd3",
        "2026-02-28 13:00:00 | cmd4"
      )

      output = capture_output { run_cli("last", "3") }

      expect(output).to include("Last 3 saved commands:")
      expect(output).to include("1.")
      expect(output).to include("cmd2")
      expect(output).to include("2.")
      expect(output).to include("cmd3")
      expect(output).to include("3.")
      expect(output).to include("cmd4")
      expect(output).not_to include("cmd1")
    end

    it "shows message when no saved commands exist" do
      output = capture_output { run_cli("last") }
      expect(output).to include("No saved commands yet")
    end

    it "shows message when no saved commands exist for last N" do
      output = capture_output { run_cli("last", "5") }
      expect(output).to include("No saved commands yet")
    end

    it "rejects invalid number" do
      output = capture_output { run_cli("last", "abc") }
      expect(output).to include("Invalid number")
    end

    it "rejects zero for last" do
      output = capture_output { run_cli("last", "0") }
      expect(output).to include("positive number")
    end
  end

  describe "grab day" do
    it "shows commands saved in the last 24 hours" do
      now = Time.now
      recent = now.strftime("%Y-%m-%d %H:%M:%S")
      old = (now - 90_000).strftime("%Y-%m-%d %H:%M:%S")

      seed_storage(
        "#{old} | old command",
        "#{recent} | recent command"
      )

      output = capture_output { run_cli("day") }

      expect(output).to include("Commands saved in the last 24 hours:")
      expect(output).to include("recent command")
      expect(output).not_to include("old command")
    end

    it "shows message when no recent commands" do
      old = (Time.now - 90_000).strftime("%Y-%m-%d %H:%M:%S")
      seed_storage("#{old} | old command")

      output = capture_output { run_cli("day") }
      expect(output).to include("No commands saved in the last 24 hours")
    end

    it "shows message when file is empty" do
      output = capture_output { run_cli("day") }
      expect(output).to include("No commands saved in the last 24 hours")
    end
  end

  describe "grab wipe" do
    it "clears the file" do
      seed_storage("2026-02-28 10:00:00 | something")

      output = capture_output { run_cli("wipe") }

      expect(output).to include("All saved commands have been cleared")
      expect(File.exist?(storage_file)).to be true
      expect(File.empty?(storage_file)).to be true
    end
  end

  describe "grab all" do
    it "prints all saved commands" do
      seed_storage(
        "2026-02-28 10:00:00 | cmd1",
        "2026-02-28 11:00:00 | cmd2",
        "2026-02-28 12:00:00 | cmd3"
      )

      output = capture_output { run_cli("all") }

      expect(output).to include("All saved commands (3):")
      expect(output).to include("cmd1")
      expect(output).to include("cmd2")
      expect(output).to include("cmd3")
    end

    it "shows message when no saved commands" do
      output = capture_output { run_cli("all") }
      expect(output).to include("No saved commands yet")
    end
  end

  describe "unknown command" do
    it "shows error and help" do
      output = capture_output { run_cli("foobar") }

      expect(output).to include("Unknown command: foobar")
      expect(output).to include("Usage:")
    end
  end

  private

  def capture_output
    output = StringIO.new
    original_stdout = $stdout
    $stdout = output
    yield
    output.string
  ensure
    $stdout = original_stdout
  end
end
