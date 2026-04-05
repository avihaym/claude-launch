#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_NAME="claude-launch"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { printf "${GREEN}[✓]${NC} %s\n" "$1"; }
warn()  { printf "${YELLOW}[!]${NC} %s\n" "$1"; }

detect_shell() {
  local shell_name
  shell_name="$(basename "${SHELL:-/bin/bash}")"
  case "$shell_name" in
    zsh)  echo "zsh" ;;
    bash) echo "bash" ;;
    fish) echo "fish" ;;
    *)    echo "unknown" ;;
  esac
}

get_rc_file() {
  case "$1" in
    zsh)  echo "${ZDOTDIR:-$HOME}/.zshrc" ;;
    bash)
      if [[ -f "$HOME/.bash_profile" ]]; then
        echo "$HOME/.bash_profile"
      else
        echo "$HOME/.bashrc"
      fi
      ;;
    fish) echo "${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish" ;;
  esac
}

get_integration_file() {
  case "$1" in
    zsh)  echo "$REPO_DIR/integrations/claude-launch.zsh" ;;
    bash) echo "$REPO_DIR/integrations/claude-launch.bash" ;;
    fish) echo "$REPO_DIR/integrations/claude-launch.fish" ;;
  esac
}

SOURCE_LINE_MARKER="# claude-launch:managed"

install() {
  echo ""
  echo "  claude-launch installer"
  echo "  ─────────────────────────"
  echo ""

  if ! command -v fzf &>/dev/null; then
    warn "fzf is not installed (required dependency)"
    echo "  Install it first:"
    echo "    macOS:  brew install fzf"
    echo "    Linux:  sudo apt install fzf"
    echo "    Other:  https://github.com/junegunn/fzf#installation"
    echo ""
  fi

  chmod +x "$REPO_DIR/bin/$BIN_NAME"
  info "Made bin/$BIN_NAME executable"

  local shell_type
  shell_type="$(detect_shell)"

  if [[ "$shell_type" == "unknown" ]]; then
    warn "Could not detect shell (got: $SHELL)"
    echo "  Manual setup: source the integration file for your shell from integrations/"
    exit 0
  fi

  info "Detected shell: $shell_type"

  local rc_file integration_file source_line
  rc_file="$(get_rc_file "$shell_type")"
  integration_file="$(get_integration_file "$shell_type")"

  source_line="export _claude_launch_dir=\"$REPO_DIR\" && source \"$integration_file\" $SOURCE_LINE_MARKER"

  if [[ -f "$rc_file" ]] && grep -qF "$SOURCE_LINE_MARKER" "$rc_file"; then
    info "Already installed in $rc_file"
  else
    echo "" >> "$rc_file"
    echo "$source_line" >> "$rc_file"
    info "Added source line to $rc_file"
  fi

  echo ""
  info "Installation complete!"
  echo ""
  echo "  Usage:"
  echo "    cc            Open the picker (places command on your prompt)"
  echo "    cc --execute  Pick and run immediately"
  echo "    cc --copy     Pick and copy to clipboard"
  echo ""
  echo "  Restart your shell or run:"
  echo "    source $rc_file"
  echo ""
}

uninstall() {
  echo ""
  echo "  claude-launch uninstaller"
  echo "  ─────────────────────────"
  echo ""

  local shell_type
  shell_type="$(detect_shell)"

  if [[ "$shell_type" == "unknown" ]]; then
    warn "Could not detect shell. Remove the claude-launch source line from your shell rc file manually."
    exit 0
  fi

  local rc_file
  rc_file="$(get_rc_file "$shell_type")"

  if [[ -f "$rc_file" ]] && grep -qF "$SOURCE_LINE_MARKER" "$rc_file"; then
    local tmp_file
    tmp_file="$(mktemp)"
    grep -vF "$SOURCE_LINE_MARKER" "$rc_file" > "$tmp_file"
    if [[ "$(uname)" == "Darwin" ]]; then
      chmod "$(stat -f '%Lp' "$rc_file")" "$tmp_file"
    else
      chmod --reference="$rc_file" "$tmp_file" 2>/dev/null || true
    fi
    mv "$tmp_file" "$rc_file"
    info "Removed source line from $rc_file"
  else
    info "No source line found in $rc_file"
  fi

  echo ""
  info "Uninstalled. You can delete this folder to fully remove claude-launch."
  echo ""
}

case "${1:-}" in
  --uninstall|-u) uninstall ;;
  --help|-h)
    echo "Usage: ./install.sh [--uninstall]"
    ;;
  *) install ;;
esac
