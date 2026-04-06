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
FZF_FALLBACK_VERSION="0.61.1"
SKIP_FZF=false

get_fzf_os() {
  case "$(uname -s)" in
    Darwin) echo "darwin" ;;
    Linux)  echo "linux" ;;
    *)      echo "" ;;
  esac
}

get_fzf_arch() {
  case "$(uname -m)" in
    x86_64)        echo "amd64" ;;
    arm64|aarch64) echo "arm64" ;;
    *)             echo "" ;;
  esac
}

install_fzf_via_package_manager() {
  if [[ "$(uname -s)" == "Darwin" ]] && command -v brew &>/dev/null; then
    info "Installing fzf via Homebrew..."
    brew install fzf && return 0
  fi

  if command -v apt-get &>/dev/null; then
    info "Installing fzf via apt..."
    sudo apt-get install -y fzf && return 0
  elif command -v pacman &>/dev/null; then
    info "Installing fzf via pacman..."
    sudo pacman -S --noconfirm fzf && return 0
  elif command -v dnf &>/dev/null; then
    info "Installing fzf via dnf..."
    sudo dnf install -y fzf && return 0
  fi

  return 1
}

install_fzf_binary() {
  local os arch version url tmp_file
  os="$(get_fzf_os)"
  arch="$(get_fzf_arch)"

  if [[ -z "$os" || -z "$arch" ]]; then
    warn "Unsupported platform for binary download: $(uname -s) $(uname -m)"
    return 1
  fi

  version="$(curl -sfL https://api.github.com/repos/junegunn/fzf/releases/latest \
    | grep '"tag_name"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/' || true)"
  version="${version:-$FZF_FALLBACK_VERSION}"

  url="https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-${os}_${arch}.tar.gz"
  tmp_file="$(mktemp)"

  info "Downloading fzf v${version} for ${os}/${arch}..."
  if ! curl -fSL -o "$tmp_file" "$url"; then
    rm -f "$tmp_file"
    warn "Download failed: $url"
    return 1
  fi

  tar -xzf "$tmp_file" -C "$REPO_DIR/bin/" fzf
  chmod +x "$REPO_DIR/bin/fzf"
  rm -f "$tmp_file"
  info "fzf v${version} installed to $REPO_DIR/bin/fzf"
}

ensure_fzf() {
  if command -v fzf &>/dev/null; then
    return 0
  fi

  if [[ -x "$REPO_DIR/bin/fzf" ]]; then
    info "Using bundled fzf at $REPO_DIR/bin/fzf"
    return 0
  fi

  if [[ "$SKIP_FZF" == "true" ]]; then
    warn "fzf is not installed (skipped via --no-fzf)"
    echo "  claude-launch will not work until fzf is installed."
    echo ""
    return 0
  fi

  echo "  fzf is required but not installed."
  printf "  Install it now? [Y/n] "
  read -r answer </dev/tty || answer=""
  answer="${answer:-Y}"

  if [[ ! "$answer" =~ ^[Yy] ]]; then
    warn "Skipping fzf installation"
    echo "  claude-launch will not work until fzf is installed."
    echo ""
    return 0
  fi

  if install_fzf_via_package_manager 2>/dev/null; then
    info "fzf installed successfully"
    return 0
  fi

  if install_fzf_binary; then
    return 0
  fi

  warn "Could not install fzf automatically"
  echo "  Install it manually:"
  echo "    macOS:  brew install fzf"
  echo "    Linux:  sudo apt install fzf"
  echo "    Other:  https://github.com/junegunn/fzf#installation"
  echo ""
}

install() {
  echo ""
  echo "  claude-launch installer"
  echo "  ─────────────────────────"
  echo ""

  ensure_fzf

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
  echo "    cc            Open the picker and execute"
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

  if [[ -f "$REPO_DIR/bin/fzf" ]]; then
    rm "$REPO_DIR/bin/fzf"
    info "Removed bundled fzf binary"
  fi

  echo ""
  info "Uninstalled. You can delete this folder to fully remove claude-launch."
  echo ""
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --uninstall|-u) uninstall; exit ;;
    --no-fzf)       SKIP_FZF=true ;;
    --help|-h)      echo "Usage: ./install.sh [--uninstall] [--no-fzf]"; exit 0 ;;
    *)              echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

install
