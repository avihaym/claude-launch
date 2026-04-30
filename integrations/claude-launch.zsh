# claude-launch — zsh integration
# Source this file in your .zshrc:
#   source /path/to/claude-launch/integrations/claude-launch.zsh

: "${_claude_launch_dir:?claude-launch: _claude_launch_dir not set. Re-run install.sh}"

cc() {
  "$_claude_launch_dir/bin/claude-launch" --execute "$@"
}

_claude_launch_load_accounts() {
  local file="${CLAUDE_LAUNCH_ACCOUNTS:-$HOME/.claude-launch-accounts}"
  [[ -f "$file" ]] || return 0
  local name raw_path expanded
  while IFS='=' read -r name raw_path; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    if [[ ! "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      print -u2 "claude-launch: skipping invalid account name: $name"
      continue
    fi
    expanded="${(e)raw_path}"
    eval "cc${name}() { CLAUDE_CONFIG_DIR=${(q)expanded} cc \"\$@\"; }"
  done < "$file"
}
_claude_launch_load_accounts
unfunction _claude_launch_load_accounts
