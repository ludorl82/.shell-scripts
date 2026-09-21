#!/bin/bash
set -euo pipefail

# Script: bootstrap_mac.sh
# Purpose: Bootstrap a fresh macOS install (Apple Silicon) from nothing.
#
# The script performs the following operations:
# 1. Validates macOS and Apple Silicon.
# 2. Installs the Xcode command line tools (git, compilers).
# 3. Installs Homebrew and puts it on PATH.
# 4. Installs the formulae and casks below.
# 5. Runs upgrade_mac.sh, which does all the user-level configuration.
#
# Requires an administrator password: Homebrew and the casks ask for it.
# Everything that does NOT need admin rights lives in upgrade_mac.sh instead,
# so that script can also run on a locked-down work Mac.
#
# Usage:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/ludorl82/.shell-scripts/main/bootstrap-mac/bootstrap_mac.sh)"

SCRIPTS_REPO="https://github.com/ludorl82/.shell-scripts.git"
CONFIGS_REPO="https://github.com/ludorl82/.shell-configs.git"
SCRIPTS_DIR="$HOME/.shell-scripts"
CONFIGS_DIR="$HOME/.shell-configs"

FORMULAE=(
    git tmux neovim fzf ripgrep fd jq yq wget tree htop watch
    coreutils gnu-sed gnupg
    kubernetes-cli helm opentofu awscli gh
    node python@3.12 asciinema tmuxinator
)

CASKS=(
    alacritty keepassxc
)

section() {
    echo
    echo "=============================================================="
    echo "  $1"
    echo "=============================================================="
}

section "Validating the machine"
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only." >&2; exit 1; }
[ "$(uname -m)" = "arm64" ] || { echo "Apple Silicon only." >&2; exit 1; }
sw_vers

section "Xcode command line tools"
if xcode-select -p >/dev/null 2>&1; then
    echo "Already installed."
else
    echo "Installing -- accept the dialog, then re-run this script."
    xcode-select --install
    exit 0
fi

section "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
brew --version

section "Formulae"
brew install "${FORMULAE[@]}"

section "Casks"
brew install --cask "${CASKS[@]}"

section "Cloning the configuration repositories"
for pair in "$CONFIGS_DIR:$CONFIGS_REPO" "$SCRIPTS_DIR:$SCRIPTS_REPO"; do
    dir="${pair%%:*}"; repo="${pair#*:}"
    if [ -d "$dir/.git" ]; then
        git -C "$dir" pull --ff-only
    else
        git clone "$repo" "$dir"
    fi
done

section "Handing over to upgrade_mac.sh"
exec bash "$SCRIPTS_DIR/scripts/upgrade_mac.sh"
