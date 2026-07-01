#!/bin/bash

sudo apt update && sudo apt install -y openssh-server

SSHD_CONFIG="/etc/ssh/sshd_config"
source "$(dirname "${BASH_SOURCE[0]}")/upgrade_shell_functions.sh"

apply_all_ssh_configs
