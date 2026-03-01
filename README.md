# Tailgrab

[![Gem Version](https://badge.fury.io/rb/tailgrab.svg)](https://rubygems.org/gems/tailgrab)

A CLI tool that reads your shell history (zsh/bash), saves commands to a local file
with timestamps, and lets you recall, filter, or copy them to your clipboard.

## Install

```
gem install tailgrab
```

## Usage

```
grab 5          # Save last 5 commands from shell history
grab last       # Copy last saved command to clipboard
grab last 3     # Show last 3 saved commands
grab all        # Show all saved commands
grab day        # Show commands saved in the last 24 hours
grab wipe       # Clear all saved commands
grab help       # Show help
```

Commands are saved to `~/tailgrab.txt` with timestamps.

## Shell Setup

For best results with multiple terminals, add to your `~/.zshrc`:

```
setopt INC_APPEND_HISTORY
```

## Development

```
bundle install
bundle exec rake        # runs specs + rubocop
bundle exec rake install  # install locally
```

## License

MIT
