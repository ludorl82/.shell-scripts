#!/bin/bash

mode="${1:-unplugged}"

# Disable hibernate when plugged in
if [[ "$mode" == "unplugged" ]]; then
  sed -i 's/IdleAction=ignore/IdleAction=hibernate/' /etc/systemd/logind.conf
  #systemctl restart systemd-logind
  systemctl kill -s HUP systemd-logind
fi

# Enable hibernate when pluggin in
if [[ "$mode" == "pluggedin" ]]; then
  sed -i 's/IdleAction=hibernate/IdleAction=ignore/' /etc/systemd/logind.conf
  #systemctl restart systemd-logind
  systemctl kill -s HUP systemd-logind
fi
