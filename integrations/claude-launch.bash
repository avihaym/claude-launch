# claude-launch — bash integration
# Source this file in your .bashrc:
#   source /path/to/claude-launch/integrations/claude-launch.bash

_claude_launch_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")/.." && pwd)"

cc() {
  "$_claude_launch_dir/bin/claude-launch" --execute "$@"
}

_claude_launch_widget() {
  local tmp="$(mktemp)"
  "$_claude_launch_dir/bin/claude-launch" --output "$tmp" || { rm -f "$tmp"; return; }
  READLINE_LINE="$(cat "$tmp")"
  READLINE_POINT=${#READLINE_LINE}
  rm -f "$tmp"
}

if [[ $- == *i* ]]; then
  bind -x '"\C-g": _claude_launch_widget'
fi
