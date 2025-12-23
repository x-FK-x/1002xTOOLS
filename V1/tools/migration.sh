#!/bin/bash

# === Detect version directory ===
if [[ -d /etc/godos ]]; then
  BASE_DIR="/etc/godos"
elif [[ -d /etc/modos ]]; then
  BASE_DIR="/etc/modos"
elif [[ -d /etc/wodos ]]; then
  BASE_DIR="/etc/wodos"
else
  echo "No valid *odos directory found."
  exit 1
fi

TOOLS_DIR="$BASE_DIR/tools"
OSVERSION_FILE="$TOOLS_DIR/osversion.txt"
UPDATER_FILE="$TOOLS_DIR/updater.sh"
UPDATER_URL="https://raw.githubusercontent.com/x-FK-x/1002xTOOLS/refs/heads/wodos/DEBIAN13/tools/updater.sh"

# === Update osversion.txt ===
echo "DEBIAN13" > "$OSVERSION_FILE"

# === Replace updater.sh ===
if [[ -f "$UPDATER_FILE" ]]; then
  rm -f "$UPDATER_FILE"
fi

curl -fsSL "$UPDATER_URL" -o "$UPDATER_FILE"
chmod +x "$UPDATER_FILE"

echo "Migration to DEBIAN13 completed successfully."
