#!/bin/bash

# Prüfe, ob als root gestartet, sonst sudo benutzen
if [[ $EUID -ne 0 ]]; then
  SUDO='sudo'
else
  SUDO=''
fi

function run_cmd() {
  CMD=$*
  echo "Running: $SUDO $CMD"
  $SUDO $CMD
  local STATUS=$?
  if [[ $STATUS -ne 0 ]]; then
    echo "Error: Command failed: $CMD with exit code $STATUS"
    exit $STATUS
  fi
}

echo "Starting system update..."

run_cmd apt update
run_cmd apt upgrade -y
run_cmd apt autoremove -y
run_cmd apt autoclean

echo "System update and cleanup completed successfully."
