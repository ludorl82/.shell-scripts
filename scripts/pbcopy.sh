#!/bin/bash
set -euo pipefail

input=$(cat)
input="${input%$'\n'}"

[ -z "$input" ] && exit 1

if [ "${CLIENT:-}" = "terminal" ] && [ -n "${DISPLAY:-}" ]; then
  # Windows Terminal with X11 forwarding - run in background to avoid blocking
  printf "%s" "$input" | xclip -selection clipboard
else
  # macOS iTerm2 and others - use OSC 52
  encoded=$(printf "%s" "$input" | base64 | tr -d '\n')
  
  if [ -n "$TMUX" ]; then
    # Inside tmux
    target_tty="${1:-$(tmux display-message -p "#{pane_tty}" 2>/dev/null || echo "/dev/tty")}"
    printf "\ePtmux;\e\e]52;c;%s\a\e\\" "$encoded" > "$target_tty"
  else
    # Outside tmux
    printf "\033]52;c;%s\007" "$encoded" > /dev/tty
  fi
fi
