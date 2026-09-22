#!/bin/bash
set -euo pipefail

# Script: mac_keyboard.sh
# Purpose: apply the keyboard configuration declared in
#          .shell-configs/.mac.keyboard.json -- Emacs editing keys, menu
#          shortcuts, system hotkeys and input sources -- identically on a
#          personal and a work Mac.
#
# THE DATA IS NOT HERE. What the keyboard should be lives in the JSON file
# above; this script only knows HOW to apply it, and carries the reasons each
# step is written the awkward way it is. One declaration, two machines: the
# personal Mac applies it at every darwin-rebuild, the work Mac when this is
# run by hand or through upgrade_mac.sh.
#
# NO ADMINISTRATOR RIGHTS, on purpose. Everything touched is a per-user
# preference. Nothing is installed, nothing calls sudo.
#
# FOUR TRAPS, each paid for in a real evening:
#
# 1. PATH. home-manager's activation runs without /usr/bin, and sw_vers,
#    defaults and plutil live only there. The script died on its first line
#    of output until the system paths were put back below.
#
# 2. PLIST TYPES. The short `defaults write` syntax -- "{ enabled = 1; }" --
#    makes EVERY value a string. WindowServer wants a boolean and integers
#    and ignores a string-typed entry in total silence: `defaults read` shows
#    exactly what you wrote, System Settings looks right, no key does
#    anything. Symbolic hotkeys are therefore written as XML, and verified by
#    TYPE rather than by value, since a mistyped value reads back perfect.
#
# 3. LOCALISED MENU TITLES. A menu shortcut binds to the item's TITLE, which
#    is translated, and Chrome ships its own translation rather than using
#    AppKit's. Every spelling is declared in the JSON; one that does not
#    exist simply never matches.
#
# 4. INPUT SOURCES NEED A LOGIN. Writing AppleEnabledInputSources fills the
#    list and macOS keeps it, but the text input service only re-reads that
#    list when a session opens. Until you log out and back in,
#    AppleSelectedInputSources stays empty, the layout is absent from the
#    menu, and Control-Space has nothing to switch between.
#
# Usage:
#   ./mac_keyboard.sh

# See trap 1.
PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

CONFIGS_REPO="https://github.com/ludorl82/.shell-configs.git"
CONFIGS_DIR="$HOME/.shell-configs"
DECL="$CONFIGS_DIR/.mac.keyboard.json"
DICT_SRC="$CONFIGS_DIR/.mac.DefaultKeyBinding.dict"
DICT_DST="$HOME/Library/KeyBindings/DefaultKeyBinding.dict"

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

# Fetch the declaration if it is missing. Guarded: on a Mac without the Xcode
# command line tools /usr/bin/git is a stub that opens a GUI installer, which
# during an activation would hang the switch behind a dialog nobody watches.
if [ ! -f "$DECL" ] && command -v git >/dev/null 2>&1 && git --version >/dev/null 2>&1; then
    if [ -d "$CONFIGS_DIR/.git" ]; then
        git -C "$CONFIGS_DIR" pull --ff-only >/dev/null 2>&1 || true
    else
        git clone --depth 1 "$CONFIGS_REPO" "$CONFIGS_DIR" >/dev/null 2>&1 || true
    fi
fi
[ -f "$DECL" ] || { echo "declaration absente : $DECL" >&2; exit 1; }
echo "declaration : $DECL"

section "Emacs editing keys"
if [ -f "$DICT_SRC" ]; then
    mkdir -p "$(dirname "$DICT_DST")"
    cp "$DICT_SRC" "$DICT_DST"
    echo "  $DICT_DST"
    # AppKit ignores a malformed dict in silence, which is the worst failure
    # available: the keys do nothing and nothing says why.
    if plutil -lint "$DICT_DST" >/dev/null 2>&1; then
        echo "  syntaxe: valide"
    else
        echo "  ! syntaxe INVALIDE -- macOS ignorera le fichier sans rien dire"
        plutil -lint "$DICT_DST" 2>&1 | sed 's/^/    /'
    fi
else
    echo "  ! $DICT_SRC absent, les touches d'edition ne sont pas posees"
fi

section "Applying the declaration"
# errexit desactive le temps du bloc : on VEUT lire son code de retour et
# continuer, pas mourir avant de l'avoir recupere.
set +e
python3 - "$DECL" <<'APPLY'
import json, subprocess, sys

MODS = {"shift": 131072, "control": 262144, "option": 524288, "command": 1048576}
decl = json.load(open(sys.argv[1]))
rc = 0

def defaults(*args):
    return subprocess.run(["defaults", *args], capture_output=True, text=True)

# --- menu shortcuts -------------------------------------------------------
print("  raccourcis d'entrees de menu")
for domain, titles in decl.get("menu_shortcuts", {}).items():
    if domain.startswith("_"):
        continue
    target = "-g" if domain == "NSGlobalDomain" else domain
    for title, combo in titles.items():
        if title.startswith("_"):
            continue
        r = defaults("write", target, "NSUserKeyEquivalents", "-dict-add", title, combo)
        if r.returncode:
            print("    ! %s / %s : %s" % (domain, title, r.stderr.strip())); rc = 1
        else:
            print("    %-16s %-18s %s" % (domain, title, combo))

# --- symbolic hotkeys, written as XML so the types are real (trap 2) ------
print("  raccourcis systeme")
XML = ("<dict><key>enabled</key><true/><key>value</key><dict>"
       "<key>parameters</key><array>"
       "<integer>%d</integer><integer>%d</integer><integer>%d</integer>"
       "</array><key>type</key><string>standard</string></dict></dict>")
wanted = {}
for e in decl.get("symbolic_hotkeys", {}).get("entries", []):
    mods = sum(MODS[m] for m in e["modifiers"])
    r = defaults("write", "com.apple.symbolichotkeys", "AppleSymbolicHotKeys",
                 "-dict-add", str(e["id"]), XML % (e["char"], e["keycode"], mods))
    if r.returncode:
        print("    ! id %s : %s" % (e["id"], r.stderr.strip())); rc = 1
    else:
        print("    id %-4s %s" % (e["id"], e["what"]))
        wanted[str(e["id"])] = True

# Verify the TYPE, not the value: a mistyped value reads back perfect.
import plistlib, os
try:
    hk = plistlib.load(open(os.path.expanduser(
        "~/Library/Preferences/com.apple.symbolichotkeys.plist"), "rb"))["AppleSymbolicHotKeys"]
    bad = []
    for k in wanted:
        e = hk.get(k)
        if not e:
            bad.append("%s absent" % k); continue
        if not isinstance(e.get("enabled"), bool):
            bad.append("%s enabled est %s" % (k, type(e["enabled"]).__name__))
        if any(not isinstance(v, int) for v in e["value"]["parameters"]):
            bad.append("%s parametres non entiers" % k)
    if bad:
        print("    ! TYPES INVALIDES, WindowServer les ignorera en silence :")
        for b in bad:
            print("      -", b)
        rc = 1
    else:
        print("    types verifies : booleen et entiers")
except Exception as exc:
    print("    ! verification des types impossible :", exc); rc = 1

# --- input sources --------------------------------------------------------
src = decl.get("input_sources", {})
print("  sources de saisie")
if src.get("show_menu"):
    # A separate preference in its own domain, false by default. Without it
    # the icon never appears and the whole thing looks like it failed.
    defaults("write", "com.apple.TextInputMenu", "visible", "-bool", "true")
    print("    menu de saisie affiche")

export = defaults("export", "com.apple.HIToolbox", "-")
if export.returncode:
    print("    ! export du domaine impossible, sources inchangees"); rc = 1
else:
    import tempfile
    d = plistlib.loads(export.stdout.encode("utf-8", "surrogateescape"))
    srcs = d.get("AppleEnabledInputSources", [])
    changed = False
    # Named one at a time, never a blanket "keep only these": on a work Mac
    # that would silently delete layouts this script knows nothing about.
    for name in src.get("drop", []):
        keep = [s for s in srcs if s.get("KeyboardLayout Name") != name]
        if len(keep) != len(srcs):
            print("    retiree : %s" % name); srcs, changed = keep, True
    for w in src.get("want", []):
        if any(s.get("KeyboardLayout Name") == w["name"] for s in srcs):
            print("    deja la : %s" % w["name"]); continue
        srcs.append({"InputSourceKind": "Keyboard Layout",
                     "KeyboardLayout ID": int(w["id"]),
                     "KeyboardLayout Name": w["name"]})
        print("    ajoutee : %s (id %s)" % (w["name"], w["id"])); changed = True
    if changed:
        d["AppleEnabledInputSources"] = srcs
        with tempfile.NamedTemporaryFile(suffix=".plist", delete=False) as f:
            plistlib.dump(d, f); tmp = f.name
        # Imported THROUGH cfprefsd rather than written to the plist file
        # behind the preferences daemon's back.
        r = defaults("import", "com.apple.HIToolbox", tmp)
        os.unlink(tmp)
        if r.returncode:
            print("    ! import refuse, sources inchangees"); rc = 1
        else:
            print("    -> deconnecte-toi pour que le systeme les enregistre (piege 4)")

sys.exit(rc)
APPLY
APPLIED=$?
set -e

ACTIVATE=/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings
if [ -x "$ACTIVATE" ]; then
    "$ACTIVATE" -u >/dev/null 2>&1 && echo "  reglages recharges sans deconnexion" \
        || echo "  ! rechargement refuse, deconnecte-toi pour appliquer"
fi

section "Readback"
echo "  -- global"
defaults read -g NSUserKeyEquivalents 2>/dev/null | sed 's/^/  /' || echo "  aucun"
echo "  -- Chrome"
defaults read com.google.Chrome NSUserKeyEquivalents 2>/dev/null | sed 's/^/  /' || echo "  aucun"
echo "  -- sources de saisie"
defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null \
    | grep 'KeyboardLayout Name' | sed 's/^ */  /' || echo "  aucune"

section "Done"
cat <<'NOTE'
Les raccourcis de menu ne sont lus qu'au demarrage d'une application. Chrome
doit donc etre RELANCE, et Commande-W ne fermera plus l'onglet :
NSUserKeyEquivalents REMPLACE le raccourci d'une entree de menu, il n'en
ajoute pas un deuxieme.

UNE SOURCE DE SAISIE AJOUTEE EXIGE UNE RECONNEXION. Voir le piege 4 en tete
de ce fichier. Les fois suivantes, l'entree etant deja la, rien ne bouge.

LES BUREAUX DOIVENT EXISTER. Ce script pose les raccourcis, il ne peut pas
creer les bureaux : leur nombre appartient au Dock et aucune preference
publique ne le fixe. Un raccourci vers un bureau absent ne fait rien. Ouvre
Mission Control et clique le + jusqu'a en avoir autant que de raccourcis
declares. A faire une fois par machine.
NOTE
exit $APPLIED
