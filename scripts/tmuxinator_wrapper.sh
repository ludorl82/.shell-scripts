#!/bin/bash
set -euo pipefail

display="${1:-}"

if [ -z "$display" ]; then
  echo "Display $display cannot be empty"
  exit 1
fi

if [ "${ENV:-}" != "console" ]; then
  echo "Invalid env: ${ENV:-}"
  exit 1
fi

case "$display" in
  console|ide) exec tmuxinator "$display" ;;
  *) echo "Env: $ENV cannot open display: $display"; exit 1 ;;
esac
