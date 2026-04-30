# claude-launch — fish integration
# Source this file in your config.fish:
#   source /path/to/claude-launch/integrations/claude-launch.fish

set -g _claude_launch_dir (realpath (status dirname)/..)

function cc --description "Fuzzy launcher for Claude Code"
    "$_claude_launch_dir"/bin/claude-launch --execute $argv
end

function _claude_launch_load_accounts
    set -l file
    if set -q CLAUDE_LAUNCH_ACCOUNTS
        set file $CLAUDE_LAUNCH_ACCOUNTS
    else
        set file $HOME/.claude-launch-accounts
    end
    test -f "$file"; or return 0
    while read -l line
        set -l trimmed (string trim -- "$line")
        test -z "$trimmed"; and continue
        string match -q "#*" -- "$trimmed"; and continue
        set -l parts (string split -m 1 '=' -- "$line")
        test (count $parts) -eq 2; or continue
        set -l name (string trim -- $parts[1])
        set -l raw_path (string trim -- $parts[2])
        if not string match -qr '^[A-Za-z_][A-Za-z0-9_]*$' -- "$name"
            echo "claude-launch: skipping invalid account name: $name" >&2
            continue
        end
        set -l expanded (eval "echo $raw_path")
        set -l escaped (string escape -- "$expanded")
        eval "function cc$name --description 'claude-launch (account: $name)'; set -lx CLAUDE_CONFIG_DIR $escaped; cc \$argv; end"
    end < "$file"
end
_claude_launch_load_accounts
functions -e _claude_launch_load_accounts

function _claude_launch_widget
    set -l tmp (mktemp)
    "$_claude_launch_dir"/bin/claude-launch --output "$tmp"
    or begin; rm -f "$tmp"; return; end

    set -l cmd (cat "$tmp")
    rm -f "$tmp"
    if test -n "$cmd"
        commandline --replace "$cmd"
    end
    commandline -f repaint
end

if status is-interactive
    bind \cg _claude_launch_widget
end
