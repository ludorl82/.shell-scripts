#!/bin/bash

apt update && apt install -y openssh-server
mkdir /run/sshd
ssh-keygen -A

# Ensure SSH configs are done
SSHD_CONFIG="/etc/ssh/sshd_config"
SSH_CONFIG1="X11Forwarding yes"
SSH_CONFIG2="AcceptEnv LANG LC_* ENV CLIENT"
if [[ "$(grep "^$SSH_CONFIG1" $SSHD_CONFIG | wc -l)" == "0" ]]; then
  echo "${SSH_CONFIG1}" | sudo tee -a $SSHD_CONFIG
  echo Just applied $SSH_CONFIG1
else
  echo $SSH_CONFIG1 already configured
fi
if [[ "$(grep "${SSH_CONFIG2:20}" $SSHD_CONFIG | wc -l)" = "0" ]]; then
  echo "${SSH_CONFIG2}" | sudo tee -a $SSHD_CONFIG
  echo Just applied $SSH_CONFIG2
else
  echo $SSH_CONFIG2 already configured
fi
