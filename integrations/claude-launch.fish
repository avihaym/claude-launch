# claude-launch — fish integration
# Source this file in your config.fish:
#   source /path/to/claude-launch/integrations/claude-launch.fish

set -g _claude_launch_dir (realpath (status dirname)/..)

function cc --description "Fuzzy launcher for Claude Code"
    set -l tmp (mktemp)
    "$_claude_launch_dir"/bin/claude-launch --output "$tmp" $argv
    or begin; rm -f "$tmp"; return 0; end

    set -l cmd (cat "$tmp")
    rm -f "$tmp"
    if test -n "$cmd"
        commandline --replace "$cmd"
    end
end

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
