# claude-launch — zsh integration
# Source this file in your .zshrc:
#   source /path/to/claude-launch/integrations/claude-launch.zsh

: "${_claude_launch_dir:?claude-launch: _claude_launch_dir not set. Re-run install.sh}"

cc() {
  local tmp="$(mktemp)"
  "$_claude_launch_dir/bin/claude-launch" --output "$tmp" "$@" || { rm -f "$tmp"; return 0; }
  local cmd="$(<"$tmp")"
  rm -f "$tmp"
  [[ -n "$cmd" ]] && print -z "$cmd"
}
