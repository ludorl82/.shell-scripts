#!/bin/bash

if [[ ! -z "$DISPLAY" ]]; then
  xclip </dev/stdin
elif [[ "$CLIENT" = "termux" ]]; then
  string="$(</dev/stdin)"
  echo -n "$string" | ssh -p8022 u0_a311@localhost 'cat | termux-clipboard-set'
elif [[ "$CLIENT" = "mintty" ]]; then
  string="$(</dev/stdin)"
  if [[ "$(tmux ls | grep mintty-ssh | wc -l)" -eq "0" ]]; then
    tmux new-session -d -s mintty-ssh 'ssh -o StrictHostKeyChecking=no -p8023 rpsja772@127.0.0.1'
    sleep 2
  fi
  echo -n "$string" > /home/rpsja772/tmp/mintty-ssh
  tmux send-keys -t mintty-ssh "ssh -o StrictHostKeyChecking=no -p2222 rpsja772@127.0.0.1 cat /home/rpsja772/tmp/mintty-ssh > /dev/clipboard" ENTER
else
  echo "No clipboard sync method" && exit 0
fi
