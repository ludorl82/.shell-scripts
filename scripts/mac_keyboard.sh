#!/bin/bash
set -euo pipefail

# Script: mac_keyboard.sh
# Purpose: macOS keyboard shortcuts -- Emacs editing keys, and a window
# maximize hotkey -- applied identically on a personal and a work Mac.
#
# NO ADMINISTRATOR RIGHTS, on purpose, exactly like upgrade_mac.sh. Everything
# it touches is a per-user preference: ~/Library/KeyBindings and the user's own
# defaults domain. Nothing is installed system-wide and nothing calls sudo, so
# this runs on a managed work Mac.
#
# WHY NO RECTANGLE, MAGNET OR AMETHYST. macOS tiles windows natively since 15,
# under Window > Move & Resize, and ANY menu item can be given a shortcut
# through NSUserKeyEquivalents -- a plain user preference. So the maximize key
# needs no third-party app, which a managed Mac may well refuse to install.
#
# THE MENU TITLE IS LOCALIZED, and the binding matches on the title, not on an
# identifier. Read out of AppKit's MenuCommands.loctable:
#
#     en      Fill
#     fr      Remplir
#     fr-CA   Remplissage
#
# All three are bound. A title that does not exist on this machine simply never
# matches, so one file covers an English work Mac and a French personal one.
#
# The Emacs keys themselves live in .shell-configs/.mac.DefaultKeyBinding.dict,
# beside .laptop.bindings.ahk which does the same job under Windows. Only the
# bindings macOS LACKS are declared there; see that file for which are native.
#
# Usage:
#   ./mac_keyboard.sh

CONFIGS_REPO="https://github.com/ludorl82/.shell-configs.git"
CONFIGS_DIR="$HOME/.shell-configs"
DICT_SRC="$CONFIGS_DIR/.mac.DefaultKeyBinding.dict"
DICT_DST="$HOME/Library/KeyBindings/DefaultKeyBinding.dict"

# Control + Option + Command + M. Same fingers as ^!#m on the Windows laptop.
MAXIMIZE_KEY="^~@m"
FILL_TITLES=("Fill" "Remplir" "Remplissage")

section() {
    echo
    echo "=============================================================="
    echo "  $1"
    echo "=============================================================="
}

section "Validating the machine"
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only." >&2; exit 1; }
[ "$(id -u)" -ne 0 ] || { echo "Do not run this as root." >&2; exit 1; }
echo "$(sw_vers -productName) $(sw_vers -productVersion) sur $(uname -m)"

section "Emacs editing keys"
if [ ! -f "$DICT_SRC" ]; then
    # Not fatal: a work Mac may block GitHub. Say so and keep going, the
    # menu shortcut below does not depend on the repository.
    if [ -d "$CONFIGS_DIR/.git" ]; then
        git -C "$CONFIGS_DIR" pull --ff-only >/dev/null 2>&1 || true
    else
        git clone --depth 1 "$CONFIGS_REPO" "$CONFIGS_DIR" >/dev/null 2>&1 || true
    fi
fi
if [ -f "$DICT_SRC" ]; then
    mkdir -p "$(dirname "$DICT_DST")"
    cp "$DICT_SRC" "$DICT_DST"
    echo "  $DICT_DST"
    # A malformed dict is ignored in silence by AppKit, which is the worst
    # possible failure: the keys just do nothing and nothing says why.
    if plutil -lint "$DICT_DST" >/dev/null 2>&1; then
        echo "  syntaxe: valide"
    else
        echo "  ! syntaxe INVALIDE -- macOS ignorera le fichier sans rien dire"
        plutil -lint "$DICT_DST" 2>&1 | sed 's/^/    /'
    fi
else
    echo "  ! $DICT_SRC absent, les touches d'edition ne sont pas posees"
fi

section "Window maximize on Control-Option-Command-M"
for title in "${FILL_TITLES[@]}"; do
    defaults write -g NSUserKeyEquivalents -dict-add "$title" "$MAXIMIZE_KEY"
    echo "  « $title » -> $MAXIMIZE_KEY"
done

section "Readback"
defaults read -g NSUserKeyEquivalents 2>/dev/null | sed 's/^/  /' \
    || echo "  ! rien n'a ete enregistre"

section "Done"
cat <<'NOTE'
Les deux reglages ne sont lus qu'au demarrage d'une application. Ferme et
rouvre celles qui comptent, ou deconnecte-toi pour tout reprendre d'un coup.

Si le raccourci de maximisation ne fait rien dans une application, c'est
qu'elle n'a pas le menu Fenetre > Deplacer et redimensionner : les
applications qui ne sont pas Cocoa, comme certaines fenetres Java ou X11,
n'ont pas de menu a lier.
NOTE
