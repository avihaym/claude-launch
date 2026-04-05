#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
COMMANDS_FILE="$BASE_DIR/commands.txt"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
  cat <<'EOF'
sync-flags — keep commands.txt in sync with claude --help

Usage:
  sync-flags.sh          Show new and removed flags
  sync-flags.sh --add    Append new flags to commands.txt with placeholder descriptions
  sync-flags.sh --help   Show this help
EOF
  exit 0
}

extract_help_flags() {
  claude --help 2>&1 \
    | grep -E '^\s+(-[a-zA-Z],\s+)?--' \
    | sed 's/^ *//' \
    | sed 's/^-[a-zA-Z], *//' \
    | while IFS= read -r line; do
        local flag desc
        flag="$(echo "$line" | sed 's/^\(--[a-zA-Z][-a-zA-Z]*\).*/\1/')"
        # description: take text after the wide alignment gap
        desc="$(echo "$line" | sed 's/^.*[[:space:]][[:space:]][[:space:]]*//')"
        echo "$flag|$desc"
      done \
    | sort -u -t'|' -k1,1
}

extract_commands_flags() {
  grep -oE '\-\-[a-zA-Z][-a-zA-Z]*' "$COMMANDS_FILE" 2>/dev/null | sort -u
}

main() {
  local mode="report"

  for arg in "$@"; do
    case "$arg" in
      --add)  mode="add" ;;
      --help|-h) usage ;;
    esac
  done

  if ! command -v claude &>/dev/null; then
    echo "Error: claude CLI not found in PATH" >&2
    exit 1
  fi

  local help_flags existing_flags
  help_flags="$(extract_help_flags)"
  existing_flags="$(extract_commands_flags)"

  local new_flags=()
  local new_descs=()
  while IFS='|' read -r flag desc; do
    if ! echo "$existing_flags" | grep -qFx -- "$flag"; then
      new_flags+=("$flag")
      new_descs+=("$desc")
    fi
  done <<< "$help_flags"

  local removed_flags=()
  while IFS= read -r flag; do
    [[ -z "$flag" ]] && continue
    if ! echo "$help_flags" | grep -qF -- "${flag}|"; then
      removed_flags+=("$flag")
    fi
  done <<< "$existing_flags"

  echo ""
  echo "  claude-launch flag sync"
  echo "  ───────────────────────"
  echo ""

  if [[ ${#new_flags[@]} -eq 0 ]]; then
    printf "${GREEN}[✓]${NC} commands.txt is up to date — no new flags\n"
  else
    printf "${YELLOW}[!]${NC} %d new flag(s) found:\n\n" "${#new_flags[@]}"
    for i in "${!new_flags[@]}"; do
      local flag="${new_flags[$i]}"
      local desc="${new_descs[$i]}"
      # truncate long descriptions
      if [[ ${#desc} -gt 60 ]]; then
        desc="${desc:0:57}..."
      fi
      printf "  %-30s %s\n" "$flag" "$desc"
    done
  fi

  echo ""

  if [[ ${#removed_flags[@]} -eq 0 ]]; then
    printf "${GREEN}[✓]${NC} No removed flags\n"
  else
    printf "${RED}[!]${NC} %d flag(s) in commands.txt but not in claude --help:\n\n" "${#removed_flags[@]}"
    for flag in "${removed_flags[@]}"; do
      echo "  $flag"
    done
  fi

  echo ""

  if [[ "$mode" == "add" && ${#new_flags[@]} -gt 0 ]]; then
    echo "" >> "$COMMANDS_FILE"
    echo "# ── New flags (added by sync-flags.sh) ────────────────────" >> "$COMMANDS_FILE"
    echo "" >> "$COMMANDS_FILE"
    for i in "${!new_flags[@]}"; do
      local flag="${new_flags[$i]}"
      local desc="${new_descs[$i]}"
      if [[ ${#desc} -gt 40 ]]; then
        desc="${desc:0:37}..."
      fi
      printf "%-20s | %-40s | %-50s | flag\n" "$flag" "$desc" "$flag" >> "$COMMANDS_FILE"
    done
    printf "${GREEN}[✓]${NC} Added %d flag(s) to commands.txt\n" "${#new_flags[@]}"
    echo "  Review and update descriptions: $COMMANDS_FILE"
    echo ""
  elif [[ "$mode" == "report" && ${#new_flags[@]} -gt 0 ]]; then
    echo "  Run with --add to append new flags to commands.txt"
    echo ""
  fi
}

main "$@"
