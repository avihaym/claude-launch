# claude-launch

Fuzzy launcher for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI flags and commands.

Stop memorizing flags. Just pick them.

![demo](./assets/demo.gif)

## What it does

Type `cc` and get an interactive fuzzy picker with all Claude Code flags:

- **Presets** — common flag combos, ready to run
- **Flags** — Tab to multi-select, compose your own command
- Selected command executes immediately

```
$ cc
  --continue          Pick up the last conversation
  --resume            Resume a specific session by ID
  auto mode           Skip all permission prompts
  --worktree          Run in an isolated git worktree
  ...

Tab-select multiple flags:
  ▶ --worktree
  ▶ --tmux
  ▶ auto mode
  → claude --worktree --tmux --permission-mode auto
```

## Requirements

- [fzf](https://github.com/junegunn/fzf) — installed automatically by `install.sh` if missing
- Bash 4+, Zsh, or Fish
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed

## Installation

### Quick install

```bash
git clone https://github.com/avihaym/claude-launch.git ~/.claude-launch
cd ~/.claude-launch
./install.sh
```

The installer detects your shell, adds the integration, and installs fzf if needed (via your package manager or a direct binary download).

Installer flags:
- `--no-fzf` — skip automatic fzf installation
- `--no-accounts` — skip the multi-account setup wizard
- `--uninstall` / `-u` — remove the integration from your shell rc

### Manual install

**Zsh** — add to `~/.zshrc`:
```zsh
export _claude_launch_dir="/path/to/claude-launch" && source "$_claude_launch_dir/integrations/claude-launch.zsh"
```

**Bash** — add to `~/.bashrc`:
```bash
source /path/to/claude-launch/integrations/claude-launch.bash
```

**Fish** — add to `~/.config/fish/config.fish`:
```fish
source /path/to/claude-launch/integrations/claude-launch.fish
```


## Usage

### Interactive picker

```bash
cc              # Pick command → execute immediately
cc resume       # Pre-filter picker with "resume"
cc --copy       # Pick and copy to clipboard
cc --help       # Show help
```

### Multi-select

Press **Tab** to select multiple flags, then **Enter** to compose them:

```
  ▶ --worktree
  ▶ --tmux
  ▶ auto mode
  → claude --worktree --tmux --permission-mode auto
```

If you select a **preset**, it takes priority and is used as the full command.

## Customization

### Add your own commands

Create `~/.claude-launch.txt` with the same format (4 columns):

```
my combo     | Worktree with Opus model              | claude --worktree --model opus   | preset
--name       | Set a display name for the session     | --name                           | flag
```

These are merged with the defaults automatically.

### Override defaults

Set environment variables to point to custom files:

```bash
export CLAUDE_LAUNCH_COMMANDS="/path/to/my/commands.txt"
export CLAUDE_LAUNCH_USER_COMMANDS="/path/to/my/overrides.txt"
```

### Change the alias name

The integrations define `cc` as the function name. To change it, edit the integration file for your shell and rename the function.

## Multiple accounts

Each Claude Code account (work, personal, client, …) lives under its own config directory via the `CLAUDE_CONFIG_DIR` environment variable — credentials, sessions, and settings are fully isolated per directory. `claude-launch` auto-generates a `cc<name>` shell alias for each account you configure.

### Set up at install time

Run `./install.sh` and answer **yes** to the *Set up multiple Claude accounts?* prompt. The wizard creates each config dir, runs `claude auth login` for each, and writes the entries to `~/.claude-launch-accounts`.

### Add an account later

```bash
./scripts/new-account.sh work
# default path: $HOME/.claude-work
# or: ./scripts/new-account.sh work /custom/path
```

This creates the dir, runs `claude auth login` with `CLAUDE_CONFIG_DIR` set, appends the entry, and prints a reminder to re-source your shell rc.

### How aliases work

After setup, each line in `~/.claude-launch-accounts`:

```
work=$HOME/.claude-work
personal=$HOME/.claude-personal
```

becomes a shell function on next shell start:

```bash
cc           # default — uses ~/.claude/
ccwork       # CLAUDE_CONFIG_DIR=$HOME/.claude-work cc "$@"
ccpersonal   # CLAUDE_CONFIG_DIR=$HOME/.claude-personal cc "$@"
```

Account names must be valid shell identifiers (`[A-Za-z_][A-Za-z0-9_]*`). Invalid lines are skipped with a warning at shell start; the rest still load.

Override the file location with `CLAUDE_LAUNCH_ACCOUNTS=/path/to/file`.

### Manual setup

If you prefer to do it by hand:

```bash
mkdir -p $HOME/.claude-work
CLAUDE_CONFIG_DIR=$HOME/.claude-work claude auth login
echo 'work=$HOME/.claude-work' >> ~/.claude-launch-accounts
source ~/.zshrc   # or ~/.bashrc / restart fish
```

## Keeping commands up to date

Claude Code adds new flags with each update. Run the sync script to check for new or removed flags:

```bash
./scripts/sync-flags.sh
```

To auto-append new flags with placeholder descriptions:

```bash
./scripts/sync-flags.sh --add
```

Then review `commands.txt` and update the descriptions.

## Standalone usage (no shell integration)

The core script works without any shell integration:

```bash
# Print the selected command
./bin/claude-launch

# Use in a pipe
eval "$(./bin/claude-launch)"

# Run directly
./bin/claude-launch --execute
```

## Uninstall

```bash
cd /path/to/claude-launch
./install.sh --uninstall
```

Then delete the folder.

## Contributing

1. Fork the repo
2. Add your changes
3. Submit a PR

Ideas welcome:
- New useful presets
- Shell integrations for other shells
- Improvements to the picker UX

## License

MIT
