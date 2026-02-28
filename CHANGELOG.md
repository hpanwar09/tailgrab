## [1.0] - 2026-02-28

- Complete rewrite of the CLI tool
- `grab N` saves last N commands from shell history with timestamps
- `grab last` copies last saved command to clipboard
- `grab last N` prints last N saved commands
- `grab all` prints all saved commands
- `grab day` shows commands saved in last 24 hours
- `grab wipe` clears all saved commands
- `grab help` shows usage information
- Cross-platform clipboard support (pbcopy, wl-copy, xclip, xsel)
- Reads zsh and bash history files directly
- Color-coded output with TTY detection
- Zero runtime dependencies

## [0.1.0] - 2024-12-13

- Initial release
