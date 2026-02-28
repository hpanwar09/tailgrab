# Tailgrab

Save and recall your terminal commands.

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
