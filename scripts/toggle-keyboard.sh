#!/bin/bash

if [[ -z "$1" ]]; then action=toggle
elif [[ "$1" = "lock" ]]; then action=lock
else action=unlock
fi

sleep 1

case $action in
  lock)
    [[ $(/usr/bin/ps ax | /usr/bin/grep "[e]vtest" | wc -l) -eq 0 ]] && /usr/bin/evtest --grab /dev/input/event3 | /usr/bin/sed "/(KEY_ESC)\,\ value\ 0/ q" && /usr/bin/killall /usr/bin/evtest
    ;;
  unlock)
    /usr/bin/killall /usr/bin/evtest || /usr/bin/killall evtest || true
    ;;
  toggle)
    /usr/bin/killall /usr/bin/evtest || /usr/bin/killall evtest || /usr/bin/evtest --grab /dev/input/event3 | /usr/bin/sed "/(KEY_ESC)\,\ value\ 0/ q" && /usr/bin/killall /usr/bin/evtest
    ;;
esac
