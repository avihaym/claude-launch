# claude-launch — shared account helpers
# Sourced by install.sh and scripts/new-account.sh. Not executed directly.

ACCOUNT_NAME_REGEX='^[A-Za-z_][A-Za-z0-9_]*$'

accounts_file_path() {
  echo "${CLAUDE_LAUNCH_ACCOUNTS:-$HOME/.claude-launch-accounts}"
}

default_account_path() {
  echo "$HOME/.claude-$1"
}

validate_account_name() {
  [[ "$1" =~ $ACCOUNT_NAME_REGEX ]]
}

account_exists() {
  local name="$1"
  local file
  file="$(accounts_file_path)"
  [[ -f "$file" ]] || return 1
  grep -qE "^[[:space:]]*${name}=" "$file"
}

append_account() {
  local name="$1" path="$2"
  local file
  file="$(accounts_file_path)"
  printf '%s=%s\n' "$name" "$path" >> "$file"
}
