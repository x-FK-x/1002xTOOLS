#!/bin/bash

# === Version Detection ===
VERSION=""
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

if [[ "$SCRIPT_DIR" == *"/godos"* ]]; then
  VERSION="godos"
elif [[ "$SCRIPT_DIR" == *"/modos"* ]]; then
  VERSION="modos"
elif [[ "$SCRIPT_DIR" == *"/wodos"* ]]; then
  VERSION="wodos"
else
  whiptail --title "1002xTOOLS Error" --msgbox "No valid version directory detected. Exiting." 10 50
  exit 1
fi

# === Ensure whiptail is installed ===
if ! command -v whiptail &> /dev/null; then
  echo "Whiptail is not installed. Installing..."
  sudo apt update && sudo apt install -y whiptail
  if ! command -v whiptail &> /dev/null; then
    echo "Failed to install whiptail. Exiting."
    exit 1
  fi
fi



# === Make all tools executable ===
chmod +x "$SCRIPT_DIR"/tools/*.sh 2>/dev/null
chmod -R 777 "$SCRIPT_DIR"/tools/*.sh 2>/dev/null

sudo rm "/etc/resolv.conf"
sudo cp "$SCRIPT_DIR/tools/resolv.conf" "/etc/resolv.conf"

# === Create Desktop Entry ===
DESKTOP_ENTRY_PATH="/usr/share/applications/1002xTOOLS.desktop"
if [[ ! -f "$DESKTOP_ENTRY_PATH" ]]; then
   sudo tee "$DESKTOP_ENTRY_PATH" > /dev/null <<EOF
[Desktop Entry]
Name=1002xTOOLS ($VERSION)
Exec=$SCRIPT_DIR/debui.sh
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=System;
EOF
    sudo chmod +x "$DESKTOP_ENTRY_PATH"
fi

# === Main Menu ===
CHOICE=$(whiptail --title "1002xTOOLS Menu ($VERSION)" \
  --menu "Choose a tool to launch:" 20 60 8 \
  "1" "Updater" \
  "2" "Installer" \
  "3" "Remover" \
  "4" "Debian Upgrades" \
  "5" "User Manager" \
  "6" "Keyboard Layout Manager" \
  "7" "1002xCMD Installer" \
  "8" "1002xSUDO Installer" \
  "9" "Exit" \
  3>&1 1>&2 2>&3)

case "$CHOICE" in
  "1") sudo bash "$SCRIPT_DIR/tools/updater.sh" ;;
  "2") sudo bash "$SCRIPT_DIR/tools/installer.sh" ;;
  "3") sudo bash "$SCRIPT_DIR/tools/remover.sh" ;;
  "4") sudo bash "$SCRIPT_DIR/tools/systemupgrade.sh" ;;
  "5") sudo bash "$SCRIPT_DIR/tools/adduser.sh" ;;
  "6") sudo dpkg-reconfigure keyboard-configuration  ;;
  "7") sudo bash "$SCRIPT_DIR/tools/1002xCMD-installer.sh" ;; 
  "8") sudo bash "$SCRIPT_DIR/tools/1002xSUDO-installer.sh" ;;
  "9"|*) clear; exit ;;
esac
