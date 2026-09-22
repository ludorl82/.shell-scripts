#!/bin/bash
set -euo pipefail

# Script: switch-mac.sh
# Purpose: basculer ce Mac sur la configuration nix-darwin, SANS pouvoir le
#          faire a partir d'une copie locale perimee.
#
# POURQUOI IL EXISTE. `darwin-rebuild switch --flake ~/git/.../nixos-iac`
# designe un DOSSIER, et un dossier ment des qu'il a une fusion de retard.
# Rien n'avertit : la bascule est verte, complete, et applique une version de
# la verite qui a expire. Arrive trois fois dans la meme journee, dont une ou
# une application venait d'etre declaree et n'apparaissait nulle part.
#
# CE SCRIPT DEMANDE LES DROITS ADMINISTRATEUR, contrairement a
# upgrade_mac.sh et mac_keyboard.sh. Ce n'est pas un choix : darwin-rebuild
# doit ecrire hors du dossier personnel. Il n'est donc pas utilisable tel
# quel sur un Mac gere par un employeur.
#
# Usage:
#   ./switch-mac.sh [attribut]        # attribut par defaut : macbook

REPO="${NIXOS_IAC_DIR:-$HOME/git/ludorl82/nixos-iac}"
ATTR="${1:-macbook}"
BRANCH="${NIXOS_IAC_BRANCH:-master}"

die() { printf 'switch-mac: %s\n' "$1" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || die "macOS seulement."
[ -d "$REPO/.git" ] || die "depot introuvable : $REPO"

cd "$REPO"

# Une modification non versionnee doit ARRETER la bascule : on ne devine pas
# si elle etait un essai a garder ou un oubli a jeter.
[ -z "$(git status --porcelain)" ] \
  || die "le depot a des modifications non versionnees.
Verse-les ou mets-les de cote, puis recommence :
$(git status --short | sed 's/^/  /')"

actuelle=$(git rev-parse --abbrev-ref HEAD)
[ "$actuelle" = "$BRANCH" ] \
  || die "tu es sur la branche « $actuelle », pas « $BRANCH ».
C'est peut-etre voulu ; dans ce cas bascule a la main, sciemment."

echo "== mise a jour de $REPO"
git fetch --quiet origin "$BRANCH"
avant=$(git rev-parse --short HEAD)

# --ff-only : une divergence doit echouer, jamais etre fusionnee en douce.
git merge --ff-only --quiet "origin/$BRANCH" \
  || die "ta copie locale a DIVERGE de origin/$BRANCH.
Rien n'a ete applique. Regle la divergence a la main."

apres=$(git rev-parse --short HEAD)
if [ "$avant" = "$apres" ]; then
  echo "  deja a jour : $apres"
else
  echo "  $avant -> $apres"
  git --no-pager log --oneline "$avant..$apres" | sed 's/^/    /'
fi

echo
echo "== bascule sur .#$ATTR  (revision $apres)"
echo "   les droits administrateur vont etre demandes"
exec sudo darwin-rebuild switch --flake "$REPO#$ATTR"
