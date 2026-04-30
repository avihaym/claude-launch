#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_account-helpers.sh
source "$SCRIPT_DIR/_account-helpers.sh"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { printf "${GREEN}[\xe2\x9c\x93]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[!]${NC} %s\n" "$1"; }

usage() {
  cat <<'EOF'
new-account — bootstrap a new claude-launch account

Usage:
  new-account.sh <name> [path]

Default path: $HOME/.claude-<name>

Steps performed:
  1. Validate <name> as a shell identifier
  2. mkdir -p the config dir
  3. Run `claude auth login` with CLAUDE_CONFIG_DIR set
  4. Append "<name>=<path>" to ~/.claude-launch-accounts
EOF
  exit "${1:-0}"
}

[[ $# -ge 1 ]] || usage 1
case "$1" in
  --help|-h) usage 0 ;;
esac

name="$1"

if [[ "$name" == cc* && ${#name} -gt 2 ]]; then
  printf "${YELLOW}[!]${NC} Stripping leading 'cc' so your alias is cc%s, not cc%s\n" "${name#cc}" "$name" >&2
  name="${name#cc}"
fi

path="${2:-$(default_account_path "$name")}"

if ! validate_account_name "$name"; then
  echo "Invalid account name: '$name' (must match $ACCOUNT_NAME_REGEX)" >&2
  exit 1
fi

if [[ "$path" != /* && "$path" != ~* && "$path" != \$* ]]; then
  echo "Config dir must be an absolute path; got '$path'" >&2
  exit 1
fi

if account_exists "$name"; then
  echo "Account '$name' already exists in $(accounts_file_path)" >&2
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "Error: claude CLI not found in PATH" >&2
  exit 1
fi

info "→ Alias will be: cc${name}"
info "→ Config dir:    $path"
echo ""

mkdir -p "$path"
info "Created $path"

info "Running 'claude auth login' with CLAUDE_CONFIG_DIR=$path"
CLAUDE_CONFIG_DIR="$path" claude auth login

append_account "$name" "$path"
info "Added '$name=$path' to $(accounts_file_path)"

echo ""
echo "Reload your shell to pick up the new 'cc${name}' alias:"
echo "  source ~/.zshrc   # or ~/.bashrc, or restart your fish shell"
