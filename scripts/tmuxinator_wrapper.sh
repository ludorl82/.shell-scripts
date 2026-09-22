#!/bin/bash
set -euo pipefail

# Script: tmuxinator_wrapper.sh  (alias `mux`)
# Purpose: ouvrir un agencement tmux par son nom.
#
# IL Y AVAIT ICI UN GARDE-FOU exigeant ENV=console, retire le 2026-09-22.
# Rien ne definissait cette variable : ni .shell-configs, ni .shell-scripts,
# ni nixos-iac, ni /var/lib/console/env que le module du conteneur charge et
# qui ne porte que PASS. Le controle ne passait donc sur AUCUNE machine, la
# console comprise, et il fallait exporter la variable a la main avant chaque
# appel. Il datait de l'epoque de plusieurs sockets tmux, qui n'a plus cours.
#
# Rien d'autre ne lisait $ENV : verifie sur les quatre depots avant le
# retrait. A ne pas confondre avec $CLIENT, une autre convention, lue par
# .console.zshrc.zsh et pbcopy.sh -- laissee telle quelle ici.
#
# LE SOCKET `-L console` RESTE, et il est porteur. L'entrypoint de l'image
# demarre `tmux -L console new-session -d -s console`, la session de Claude y
# vit, et modules/console-container.nix passe -L console a CHAQUE appel tmux.
# Le retirer couperait la session de Claude.

display="${1:-}"

if [ -z "$display" ]; then
  echo "usage: mux <console|ide|claude>" >&2
  exit 1
fi

case "$display" in
  console|ide) exec tmuxinator "$display" ;;
  claude)      exec tmux -L console attach -t claude ;;
  *) echo "agencement inconnu: $display (console, ide ou claude)" >&2; exit 1 ;;
esac
