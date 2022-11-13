#!/bin/bash

if [[ ! -z "$DISPLAY" ]]; then
  xclip </dev/stdin
elif [[ "$CLIENT" = "mintty" ]]; then
  string="$(</dev/stdin)"
  if [[ "$(tmux ls | grep mintty-ssh | wc -l)" -eq "0" ]]; then
    tmux new-session -d -s mintty-ssh 'ssh -o StrictHostKeyChecking=no -p8023 -R22:localhost:22 ludor@127.0.0.1'
    sleep 2
  fi
  echo -n "$string" > /home/ludorl82/tmp/mintty-ssh
  tmux send-keys -t mintty-ssh "ssh -o StrictHostKeyChecking=no ludorl82@localhost cat /home/ludorl82/tmp/mintty-ssh > /dev/clipboard" ENTER
elif [[ "$CLIENT" = "terminal" ]]; then
  string="$(</dev/stdin)"
  if [[ "$(tmux ls | grep terminal-ssh | wc -l)" -eq "0" ]]; then
    tmux new-session -d -s terminal-ssh 'ssh -o StrictHostKeyChecking=no 172.17.0.1'
    sleep 2
    tmux send-keys -t terminal-ssh "export DISPLAY=':10.0'" ENTER
  fi
  echo -n "$string" > /home/ludorl82/tmp/terminal-ssh
  tmux send-keys -t terminal-ssh "ssh -o StrictHostKeyChecking=no -p2222 localhost cat /home/ludorl82/tmp/terminal-ssh | xclip -selection clipboard" ENTER
else
  string="$(</dev/stdin)"
  if [[ "$(tmux ls | grep termux-ssh | wc -l)" -eq "0" ]]; then
    tmux new-session -d -s termux-ssh 'ssh -o StrictHostKeyChecking=no -p8022 u0_a311@127.0.0.1'
    sleep 2
  fi
  echo -n "$string" > /home/ludorl82/tmp/termux-ssh
  tmux send-keys -t termux-ssh "ssh -o StrictHostKeyChecking=no -p2222 ludorl82@ludorl82-Super-Server.local cat /home/ludorl82/tmp/termux-ssh | termux-clipboard-set" ENTER
fi
