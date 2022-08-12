#!/bin/bash

if [[ ! -z "$DISPLAY" ]]; then
  xclip </dev/stdin
elif [[ "$CLIENT" = "mintty" ]]; then
  string="$(</dev/stdin)"
  if [[ "$(tmux ls | grep mintty-ssh | wc -l)" -eq "0" ]]; then
    tmux new-session -d -s mintty-ssh 'ssh -o StrictHostKeyChecking=no -p8023 ludorl82@127.0.0.1'
    sleep 2
  fi
  echo -n "$string" > /home/ludorl82/tmp/mintty-ssh
  tmux send-keys -t mintty-ssh "ssh -o StrictHostKeyChecking=no -p2222 ludorl82@127.0.0.1 cat /home/ludorl82/tmp/mintty-ssh > /dev/clipboard" ENTER
else
  string="$(</dev/stdin)"
  if [[ "$(tmux ls | grep termux-ssh | wc -l)" -eq "0" ]]; then
    tmux new-session -d -s termux-ssh 'ssh -o StrictHostKeyChecking=no -p8022 u0_a311@127.0.0.1'
    sleep 2
  fi
  echo -n "$string" > /home/ludorl82/tmp/termux-ssh
  tmux send-keys -t termux-ssh "ssh -o StrictHostKeyChecking=no -p2222 ludorl82@ludorl82-virtual-machine.local cat /home/ludorl82/tmp/termux-ssh | termux-clipboard-set" ENTER
fi
