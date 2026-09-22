#!/bin/bash
set -euo pipefail

# Script: upgrade_mac.sh
# Purpose: Configure the console on a Mac -- shell, prompt, tmux, Alacritty.
#
# POUR LE MAC DU BUREAU, PLUS POUR LE PERSO. Depuis que le portable personnel
# est passe a nix-darwin, home-manager possede ~/.zshrc, la configuration
# d'Alacritty et ~/.config/tmuxinator, qui sont des liens vers le store en
# LECTURE SEULE. Les copier par-dessus echoue, ou remplace le lien et fait
# avorter la bascule suivante a checkLinkTargets -- partie systeme comprise.
# Le garde-fou juste avant la premiere ecriture refuse donc de tourner sur une
# machine geree par nix-darwin. Sur le perso, c'est `switch-mac`.
#
# NO ADMINISTRATOR RIGHTS. Nothing is installed system-wide, nothing calls
# sudo, and every file it touches lives under $HOME. That is deliberate: this
# script has to run on a managed work Mac, which has no Nix at all.
#
# It CONFIGURES, it does not install: tmux, neovim and Alacritty are expected
# to be there already (bootstrap_mac.sh installs them on a personal machine).
# Missing tools are reported and skipped, never fatal.
#
# Usage:
#   ./upgrade_mac.sh

CONFIGS_REPO="https://github.com/ludorl82/.shell-configs.git"
SCRIPTS_REPO="https://github.com/ludorl82/.shell-scripts.git"
CONFIGS_DIR="$HOME/.shell-configs"
SCRIPTS_DIR="$HOME/.shell-scripts"
ZSH_DIR="$HOME/.zsh"
TMUX_DIR="$HOME/.tmux"
FZF_DIR="$HOME/.fzf"
ALACRITTY_DIR="$HOME/.config/alacritty"

# Sourced from .shell-configs as .console.<name>, symlinked as ~/.<name>.
# The console files are the source of truth for the shell itself; only
# Alacritty has its own laptop variant.
ZSH_FILES=("zshrc.zsh" "bindings.zsh" "zshenv" "p10k.zsh")
TMUX_FILES=("tmux.conf" "tmux.keys.conf")

ZSH_PLUGINS=(
    "https://github.com/zsh-users/zsh-syntax-highlighting.git"
    "https://github.com/zsh-users/zsh-autosuggestions.git"
)
ZSH_THEMES=("https://github.com/romkatv/powerlevel10k.git")
TMUX_PLUGINS=(
    "https://github.com/jimeh/tmux-themepack.git"
    "https://github.com/tmux-plugins/tmux-yank.git"
)

section() {
    echo
    echo "=============================================================="
    echo "  $1"
    echo "=============================================================="
}

# Clone on first run, fast-forward afterwards. Never fatal: a work Mac may
# block GitHub, and a stale plugin is better than a failed run.
sync_repos() {
    local dir=$1; shift
    mkdir -p "$dir"
    for repo in "$@"; do
        local name; name=$(basename "$repo" .git)
        if [ -d "$dir/$name/.git" ]; then
            git -C "$dir/$name" pull --ff-only || echo "  ! $name : pull echoue, on garde la version locale"
        else
            git clone --depth 1 "$repo" "$dir/$name" || echo "  ! $name : clone echoue"
        fi
    done
}

# macOS ln has no -T, so remove first and link with an explicit target name.
link_configs() {
    local target_dir=$1; shift
    mkdir -p "$target_dir"
    for file in "$@"; do
        local src="$CONFIGS_DIR/.console.$file"
        [ -f "$src" ] || { echo "  ! absent : $src"; continue; }
        cp "$src" "$target_dir/$file"
        rm -f "$HOME/.$file"
        ln -s "$target_dir/$file" "$HOME/.$file"
        echo "  ~/.$file -> $target_dir/$file"
    done
}

section "Validating the machine"
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only." >&2; exit 1; }
[ "$(id -u)" -ne 0 ] || { echo "Do not run this as root." >&2; exit 1; }
echo "$(sw_vers -productName) $(sw_vers -productVersion) sur $(uname -m)"

# Le garde-fou. Place AVANT la premiere ecriture, pas en commentaire : un
# avertissement qu'on lit apres coup ne repare pas un dossier personnel.
if [ -d /run/current-system ] && [ -e /run/current-system/sw ]; then
    cat >&2 <<'STOP'
upgrade_mac.sh : cette machine est geree par nix-darwin.

home-manager possede deja ~/.zshrc, la configuration d'Alacritty et
~/.config/tmuxinator. Ce script les ecraserait, et la bascule suivante
avorterait au complet a checkLinkTargets, partie systeme comprise.

Sur cette machine, utilise :   switch-mac

Ce script reste celui du Mac du bureau, qui n'a pas Nix. Pour passer outre
en connaissance de cause : MAC_UPGRADE_FORCE=1 ./upgrade_mac.sh
STOP
    [ "${MAC_UPGRADE_FORCE:-0}" = "1" ] || exit 1
    echo "MAC_UPGRADE_FORCE=1 : on continue malgre tout." >&2
fi

section "Configuration repositories"
sync_repos "$HOME" "$CONFIGS_REPO" "$SCRIPTS_REPO"

section "zsh plugins and theme"
sync_repos "$ZSH_DIR/plugins" "${ZSH_PLUGINS[@]}"
sync_repos "$ZSH_DIR/themes" "${ZSH_THEMES[@]}"

section "tmux plugins"
sync_repos "$TMUX_DIR/plugins" "${TMUX_PLUGINS[@]}"

section "Shell and tmux configuration"
link_configs "$ZSH_DIR" "${ZSH_FILES[@]}"
link_configs "$TMUX_DIR" "${TMUX_FILES[@]}"
[ -f "$CONFIGS_DIR/.console.zshrc" ] && cp "$CONFIGS_DIR/.console.zshrc" "$HOME/.zshrc" && echo "  ~/.zshrc"
[ -f "$CONFIGS_DIR/.console.aliases.sh" ] && cp "$CONFIGS_DIR/.console.aliases.sh" "$HOME/.aliases.sh" && echo "  ~/.aliases.sh"
[ -f "$CONFIGS_DIR/.console.gitconfig" ] && cp "$CONFIGS_DIR/.console.gitconfig" "$HOME/.gitconfig" && echo "  ~/.gitconfig"

section "Alacritty"
if [ -f "$CONFIGS_DIR/.laptop.alacritty.toml" ]; then
    mkdir -p "$ALACRITTY_DIR"
    cp "$CONFIGS_DIR/.laptop.alacritty.toml" "$ALACRITTY_DIR/alacritty.toml"
    echo "  $ALACRITTY_DIR/alacritty.toml"
else
    echo "  ! .laptop.alacritty.toml absent du depot de configs"
fi

section "neovim and tmuxinator"
[ -d "$CONFIGS_DIR/.console.config/nvim" ] && \
    rsync -a "$CONFIGS_DIR/.console.config/nvim/" "$HOME/.config/nvim/" && echo "  ~/.config/nvim"
[ -d "$CONFIGS_DIR/.console.config/tmuxinator" ] && \
    rsync -a --delete "$CONFIGS_DIR/.console.config/tmuxinator/" "$HOME/.config/tmuxinator/" && echo "  ~/.config/tmuxinator"

section "fzf"
if [ -d "$FZF_DIR/.git" ]; then
    git -C "$FZF_DIR" pull --ff-only || true
else
    git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_DIR" || true
fi
[ -x "$FZF_DIR/install" ] && "$FZF_DIR/install" --key-bindings --completion --no-update-rc

section "macOS keyboard shortcuts"
# Emacs editing keys and the maximize hotkey. Also sudo-free, so it belongs
# in this script rather than in the bootstrap one.
if [ -x "$SCRIPTS_DIR/scripts/mac_keyboard.sh" ]; then
    "$SCRIPTS_DIR/scripts/mac_keyboard.sh" | sed 's/^/  /'
else
    echo "  ! scripts/mac_keyboard.sh introuvable"
fi

section "Tools present on this machine"
for c in git zsh tmux nvim fzf kubectl aws gh jq rg asciinema alacritty; do
    printf "  %-12s %s\n" "$c" "$(command -v "$c" >/dev/null 2>&1 && echo present || echo ABSENT)"
done

section "Done"
echo "Open a new terminal, or run: exec zsh"
