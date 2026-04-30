# claude-launch — bash integration
# Source this file in your .bashrc:
#   source /path/to/claude-launch/integrations/claude-launch.bash

_claude_launch_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")/.." && pwd)"

cc() {
  "$_claude_launch_dir/bin/claude-launch" --execute "$@"
}

_claude_launch_load_accounts() {
  local file="${CLAUDE_LAUNCH_ACCOUNTS:-$HOME/.claude-launch-accounts}"
  [[ -f "$file" ]] || return 0
  local name raw_path expanded quoted
  while IFS='=' read -r name raw_path; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    if [[ ! "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      printf 'claude-launch: skipping invalid account name: %s\n' "$name" >&2
      continue
    fi
    eval "expanded=\"$raw_path\""
    printf -v quoted '%q' "$expanded"
    eval "cc${name}() { CLAUDE_CONFIG_DIR=${quoted} cc \"\$@\"; }"
  done < "$file"
}
_claude_launch_load_accounts
unset -f _claude_launch_load_accounts

_claude_launch_widget() {
  local tmp
  tmp="$(mktemp)" || return
  if "$_claude_launch_dir/bin/claude-launch" --output "$tmp"; then
    READLINE_LINE="$(cat "$tmp")"
    READLINE_POINT=${#READLINE_LINE}
  fi
  rm -f "$tmp"
}

if [[ $- == *i* ]]; then
  bind -x '"\C-g": _claude_launch_widget'
fi
