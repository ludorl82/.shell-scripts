#!/bin/bash
set -euo pipefail

input=$(cat)
input="${input%$'\n'}"

[ -z "$input" ] && exit 1

# Il y avait ici une premiere branche, prise quand CLIENT=terminal et DISPLAY
# etaient poses, qui passait par xclip : l'epoque de Windows Terminal avec
# renvoi X11. Retiree le 2026-09-22 parce que RIEN ne definissait CLIENT, ni
# dans les depots de configs ni ailleurs, donc elle n'etait jamais prise et
# tout passait deja par OSC 52. Supprimer du code mort ne change donc rien au
# comportement ; c'est ce qui a ete verifie avant de le faire.

# OSC 52 : le terminal lui-meme met dans le presse-papiers, ce qui traverse
# ssh et tmux sans agent ni serveur X.
encoded=$(printf "%s" "$input" | base64 | tr -d '\n')

if [ -n "$TMUX" ]; then
  # Dans tmux, la sequence doit etre emballee pour traverser le multiplexeur
  # et viser le tty du panneau, pas celui du processus.
  target_tty="${1:-$(tmux display-message -p "#{pane_tty}" 2>/dev/null || echo "/dev/tty")}"
  printf "\ePtmux;\e\e]52;c;%s\a\e\\" "$encoded" > "$target_tty"
else
  printf "\033]52;c;%s\007" "$encoded" > /dev/tty
fi
