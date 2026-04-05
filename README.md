# claude-launch

Fuzzy launcher for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI flags and commands.

Stop memorizing flags. Just pick them.

![demo](./assets/demo.gif)

## What it does

Type `cc` and get an interactive fuzzy picker with all Claude Code flags:

- **Presets** — common flag combos, ready to run
- **Flags** — Tab to multi-select, compose your own command
- Selected command lands on your prompt for review before execution

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

- [fzf](https://github.com/junegunn/fzf) — the fuzzy finder
- Bash 4+, Zsh, or Fish
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed

### Install fzf

```bash
# macOS
brew install fzf

# Ubuntu / Debian
sudo apt install fzf

# Arch
sudo pacman -S fzf

# Other
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install
```

## Installation

### Quick install

```bash
git clone https://github.com/avihaym/claude-launch.git ~/.claude-launch
cd ~/.claude-launch
./install.sh
```

The installer detects your shell and adds the integration automatically.

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

### Plugin managers

**zinit:**
```zsh
zinit light avihaym/claude-launch
```

**Oh My Zsh:**
```bash
git clone https://github.com/avihaym/claude-launch.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/claude-launch
# Add to plugins in .zshrc:
plugins=(... claude-launch)
```

## Usage

### Interactive picker

```bash
cc              # Pick command → lands on your prompt (edit before running)
cc resume       # Pre-filter picker with "resume"
cc --execute    # Pick and run immediately
cc --copy       # Pick and copy to clipboard
cc --help       # Show help
```

### Keyboard shortcut

**Bash/Fish**: `Ctrl+G` opens the picker directly (configured by the integration).

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
