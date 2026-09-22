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

# home-manager's activation runs with a PATH that does NOT contain /usr/bin,
# and everything this script drives -- sw_vers, defaults, plutil -- lives
# only there. Seen for real on 2026-09-21, from a darwin-rebuild switch:
#
#   mac_keyboard.sh: line 54: sw_vers: command not found
#   ! mac_keyboard.sh a echoue : raccourcis NON appliques
#
# So put the system paths back instead of hoping the caller supplied them.
# Prepended, not appended: these are the macOS originals, and a nixpkgs
# coreutils uname earlier on the path is fine but must not shadow them.
PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

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
    # Guarded: on a Mac without the Xcode command line tools, /usr/bin/git is
    # a stub that pops a GUI installer. During an activation that would hang
    # the switch behind a dialog nobody is watching.
    if command -v git >/dev/null 2>&1 && git --version >/dev/null 2>&1; then
        if [ -d "$CONFIGS_DIR/.git" ]; then
            git -C "$CONFIGS_DIR" pull --ff-only >/dev/null 2>&1 || true
        else
            git clone --depth 1 "$CONFIGS_REPO" "$CONFIGS_DIR" >/dev/null 2>&1 || true
        fi
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
# WRITTEN AS XML, AND THAT IS THE WHOLE POINT. The short `defaults write`
# syntax -- "{ enabled = 1; parameters = (49, 18, 393216); }" -- produces a
# plist in which EVERY VALUE IS A STRING. WindowServer wants a boolean and
# integers, so it ignores such an entry in complete silence: `defaults read`
# shows exactly what you wrote, System Settings looks right, and not one key
# does anything. Two evenings went into blaming the key codes for this.
#
# First parameter is the character code of the UNSHIFTED key, matching what
# macOS writes for its own shortcuts: entry 51 is Command-Shift-` and stores
# the same character code as entry 27, plain Command-`, so holding Shift does
# not change it.
CTRL_SHIFT=$(( 262144 + 131072 ))
DESKTOP_IDS=(118 119 120 121 122)
DESKTOP_KEYS=(18 19 20 21 23)
DESKTOP_CHARS=(49 50 51 52 53)   # '1'..'5'
for i in 0 1 2 3 4; do
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
        -dict-add "${DESKTOP_IDS[$i]}" "
<dict>
  <key>enabled</key><true/>
  <key>value</key>
  <dict>
    <key>parameters</key>
    <array>
      <integer>${DESKTOP_CHARS[$i]}</integer>
      <integer>${DESKTOP_KEYS[$i]}</integer>
      <integer>$CTRL_SHIFT</integer>
    </array>
    <key>type</key><string>standard</string>
  </dict>
</dict>"
    echo "  Bureau $(( i + 1 )) <- Controle-Majuscule-$(( i + 1 ))  (id ${DESKTOP_IDS[$i]})"
done

# The guard for the bug above: a wrong TYPE reads back looking perfectly
# correct, so check the type itself, not the value.
if python3 - <<'CHECK'
import plistlib, os, sys
p = os.path.expanduser("~/Library/Preferences/com.apple.symbolichotkeys.plist")
try:
    d = plistlib.load(open(p, "rb"))["AppleSymbolicHotKeys"]
except Exception as e:
    print("    ! illisible:", e); sys.exit(1)
bad = []
for k in ("118", "119", "120", "121", "122"):
    e = d.get(k)
    if not e:
        bad.append(f"{k} absent"); continue
    if not isinstance(e.get("enabled"), bool):
        bad.append(f"{k} enabled est {type(e['enabled']).__name__}, pas bool")
    for v in e["value"]["parameters"]:
        if not isinstance(v, int):
            bad.append(f"{k} parametre {v!r} est {type(v).__name__}, pas int"); break
if bad:
    print("    ! TYPES INVALIDES, WindowServer les ignorera en silence :")
    for b in bad: print("      -", b)
    sys.exit(1)
CHECK
then
    echo "  types verifies : booleen et entiers"
else
    echo "  ! les raccourcis de bureau ne prendront PAS effet"
fi

ACTIVATE=/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings
if [ -x "$ACTIVATE" ]; then
    "$ACTIVATE" -u >/dev/null 2>&1 && echo "  reglages recharges sans deconnexion" \
        || echo "  ! rechargement refuse, deconnecte-toi pour appliquer"
else
    echo "  ! activateSettings introuvable, deconnecte-toi pour appliquer"
fi

section "Input sources: Canadian - CSA, switched with Control-Space"
# Control-Space is ALREADY the macOS shortcut for "select the previous input
# source", symbolic hotkey 60, shipped with the right key code and modifier
# and merely disabled. So this enables an existing entry rather than inventing
# one -- and it is written in XML for the same reason as the desktops above:
# the short syntax would make `enabled` the STRING "1" and WindowServer would
# ignore it without a word.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 "
<dict>
  <key>enabled</key><true/>
  <key>value</key>
  <dict>
    <key>parameters</key>
    <array><integer>32</integer><integer>49</integer><integer>262144</integer></array>
    <key>type</key><string>standard</string>
  </dict>
</dict>"
echo "  Controle-Espace : source de saisie precedente"

# Canadian - CSA is what Windows calls the Canadian Multilingual Standard.
# The three Canadian layouts macOS ships, read out of AppleKeyboardLayouts-L.dat:
#   Canadian            (id 29)   CanadianFrench-PC   Canadian - CSA   (id 80)
#
# APPENDED, never assigned. `defaults write ... -array` would replace the whole
# list, and on a work Mac that means silently deleting whatever layouts are
# already enabled there. So the domain is exported, the entry added only if
# missing, and the result imported back through cfprefsd rather than written
# to the plist file behind the preferences daemon's back.
if defaults export com.apple.HIToolbox - > /tmp/hitoolbox.$$.plist 2>/dev/null; then
    if python3 - /tmp/hitoolbox.$$.plist <<'CSA'
import plistlib, sys
p = sys.argv[1]
d = plistlib.load(open(p, "rb"))
srcs = d.get("AppleEnabledInputSources", [])
if any(s.get("KeyboardLayout Name") == "Canadian - CSA" for s in srcs):
    print("  Canadian - CSA : deja presente")
    sys.exit(1)          # rien a ecrire
srcs.append({"InputSourceKind": "Keyboard Layout",
             "KeyboardLayout ID": 80,
             "KeyboardLayout Name": "Canadian - CSA"})
d["AppleEnabledInputSources"] = srcs
plistlib.dump(d, open(p, "wb"))
print("  Canadian - CSA : ajoutee (%d sources au total)" % len(srcs))
CSA
    then
        defaults import com.apple.HIToolbox /tmp/hitoolbox.$$.plist \
            || echo "  ! import refuse, les sources de saisie sont inchangees"
    fi
    rm -f /tmp/hitoolbox.$$.plist
else
    echo "  ! export du domaine HIToolbox impossible, sources inchangees"
fi

# Showing the input menu is a SEPARATE preference in its own domain, and it
# defaults to off. Two input sources are not enough on their own: without
# this the icon never appears in the menu bar, TextInputMenuAgent never
# starts, and the whole thing looks like it failed. -bool matters here too --
# a string "1" would be ignored like everywhere else in this file.
defaults write com.apple.TextInputMenu visible -bool true
echo "  menu de saisie : affiche dans la barre des menus"

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

UNE SOURCE DE SAISIE AJOUTEE ICI N'EST PAS ENCORE ENREGISTREE. Ecrire
AppleEnabledInputSources par defaults remplit la liste, et macOS la garde,
mais le service de saisie ne relit cette liste qu'a l'OUVERTURE DE SESSION :
tant qu'on ne s'est pas deconnecte, AppleSelectedInputSources reste vide, la
disposition n'apparait pas dans le menu et Controle-Espace n'a rien entre
quoi basculer. Deconnecte-toi et reconnecte-toi une fois apres le premier
ajout. Les fois suivantes, l'entree etant deja la, le script ne touche a
rien.

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
