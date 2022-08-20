#!/bin/bash

# Set environment
export ENV=$1
export CLIENT=$2
if [[ "$(ps ax | grep sshd | grep -v grep | wc -l)" = "0" ]]; then /usr/bin/sshd; fi
ssh -o SendEnv=ENV -o SendEnv=CLIENT -o StrictHostKeyChecking=no -R 8023:localhost:22 ludorl82@ludorl82-virtual-machine.local
