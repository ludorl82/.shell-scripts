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

section "Five desktops on Control-Shift-1..5"
# Mapping read out of Apple's OWN table, not guessed:
#   KeyboardSettings.appex/Contents/Resources/DefaultSpacesShortcuts.xml
#     Desktop 1..5 -> symbolic hotkey id 118..122
#     keycodes        18  19  20  21  23   (note: 5 is 23, not 22)
#     Apple's default modifier is 262144, Control alone.
# We want Control+Shift, so 262144 + 131072 = 393216.
#
# The parameters array is (ASCII, keycode, modifiers). ASCII is 65535, which
# means "none". Apple's table gives a keycode and a modifier and no character
# at all, and with Shift held keycode 18 does not produce "1" anyway -- so
# matching on the character would be wrong, not merely redundant.
CTRL_SHIFT=$(( 262144 + 131072 ))
DESKTOP_IDS=(118 119 120 121 122)
DESKTOP_KEYS=(18 19 20 21 23)
for i in 0 1 2 3 4; do
    id="${DESKTOP_IDS[$i]}"
    kc="${DESKTOP_KEYS[$i]}"
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$id" \
        "{ enabled = 1; value = { parameters = (65535, $kc, $CTRL_SHIFT); type = standard; }; }"
    echo "  Bureau $(( i + 1 )) <- Controle-Majuscule-$(( i + 1 ))  (id $id, code $kc)"
done

ACTIVATE=/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings
if [ -x "$ACTIVATE" ]; then
    "$ACTIVATE" -u >/dev/null 2>&1 && echo "  reglages recharges sans deconnexion" \
        || echo "  ! rechargement refuse, deconnecte-toi pour appliquer"
else
    echo "  ! activateSettings introuvable, deconnecte-toi pour appliquer"
fi

section "Chrome: close tab on Control-Shift-W"
# Chrome's OWN menu, so Chrome's own defaults domain -- not -g. As above the
# binding matches the menu ITEM TITLE, but Chrome ships its own localisation
# instead of using AppKit's, so the French title was read straight out of its
# locale pak rather than guessed:
#
#   Contents/Frameworks/Google Chrome Framework.framework/Versions/*/
#     Resources/fr.lproj/locale.pak  ->  "Fermer l'onglet"
#
# Plain ASCII apostrophe, NOT the typographic one -- the difference is
# invisible on screen and would have made the binding silently never match.
# The English title is bound too, so a work Mac in English gets it as well.
#
# THE TRADE, said out loud rather than discovered later: NSUserKeyEquivalents
# REPLACES a menu item's shortcut, it does not add a second one. Command-W
# stops closing tabs. That is deliberate here -- it mirrors the Windows
# laptop, where Control-W was given to delete-word-backward and closing moved
# to Control-Shift-W -- but removing one line below gives Command-W back.
CHROME_CLOSE_TAB=("Close Tab" "Fermer l'onglet")
for title in "${CHROME_CLOSE_TAB[@]}"; do
    defaults write com.google.Chrome NSUserKeyEquivalents -dict-add "$title" '^$w'
    printf '  « %s » -> Controle-Majuscule-W\n' "$title"
done

section "Readback"
echo "  -- global"
defaults read -g NSUserKeyEquivalents 2>/dev/null | sed 's/^/  /' \
    || echo "  ! rien n'a ete enregistre"
echo "  -- Chrome"
defaults read com.google.Chrome NSUserKeyEquivalents 2>/dev/null | sed 's/^/  /' \
    || echo "  ! rien n'a ete enregistre pour Chrome"

section "Done"
cat <<'NOTE'
Les deux reglages ne sont lus qu'au demarrage d'une application. Ferme et
rouvre celles qui comptent, ou deconnecte-toi pour tout reprendre d'un coup.

Si le raccourci de maximisation ne fait rien dans une application, c'est
qu'elle n'a pas le menu Fenetre > Deplacer et redimensionner : les
applications qui ne sont pas Cocoa, comme certaines fenetres Java ou X11,
n'ont pas de menu a lier.

Chrome doit etre RELANCE pour voir sa nouvelle liaison, et Commande-W ne
fermera plus l'onglet : NSUserKeyEquivalents remplace le raccourci d'une
entree de menu, il n'en ajoute pas un deuxieme.

LES CINQ BUREAUX DOIVENT EXISTER. Ce script pose les raccourcis, il ne peut
pas creer les bureaux : leur nombre appartient au Dock, et aucune preference
publique ne le fixe. Un raccourci vers un bureau absent ne fait simplement
rien. Ouvre Mission Control (Controle-Fleche haut), clique le + en haut a
droite jusqu'a en avoir cinq. C'est a faire une fois par machine, ils
survivent aux redemarrages.
NOTE
