#!/bin/bash

# === Version Detection ===
if [[ -d /etc/godos ]]; then
  VERSION="godos"
  SCRIPT_DIR="/etc/godos"
elif [[ -d /etc/modos ]]; then
  VERSION="modos"
  SCRIPT_DIR="/etc/modos"
elif [[ -d /etc/wodos ]]; then
  VERSION="WODOS"
  SCRIPT_DIR="/etc/wodos"
else
  whiptail --title "Updater Error" --msgbox "No valid version directory detected. Exiting." 10 50
  exit 1
fi



# === Make all tools executable ===
chmod +x "$SCRIPT_DIR"/tools/*.sh 2>/dev/null
chmod -R 777 "$SCRIPT_DIR"/tools/*.sh 2>/dev/null

sudo rm "/etc/resolv.conf"
sudo cp "$SCRIPT_DIR/tools/resolv.conf" "/etc/resolv.conf"

LOCAL_DEV_FILE="$SCRIPT_DIR/dev.txt"
LOCAL_VERSION=""
if [[ -f "$LOCAL_DEV_FILE" ]]; then
  LOCAL_VERSION=$(head -n1 "$LOCAL_DEV_FILE")
fi


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
CHOICE=$(whiptail --title "1002xTOOLS Menu ($VERSION VERNO $LOCAL_VERSION)" \
  --menu "Choose a tool to launch:" 20 60 8 \
  "1" "Updater of 1002xTOOLS" \
  "2" "Installer of Software" \
  "3" "Remover of Software" \
  "4" "Debian Upgrades" \
  "5" "Add User" \
  "6" "Language Settings" \
  "7" "Keyboard Manager" \
  "8" "1002xCMD Installer" \
  "9" "1002xSUDO Installer" \
  "10" "Exit" \
  3>&1 1>&2 2>&3)

case "$CHOICE" in
  "1") sudo bash "$SCRIPT_DIR/tools/updater.sh" ;;
  "2") sudo bash "$SCRIPT_DIR/tools/installer.sh" ;;
  "3") sudo bash "$SCRIPT_DIR/tools/remover.sh" ;;
  "4") sudo bash "$SCRIPT_DIR/tools/systemupgrade.sh" ;;
  "5") sudo bash "$SCRIPT_DIR/tools/adduser.sh" ;;
  "6") sudo dpkg-reconfigure locales  ;;
  "7") sudo dpkg-reconfigure keyboard-configuration  ;;
  "8") sudo bash "$SCRIPT_DIR/tools/1002xCMD-installer.sh" ;; 
  "9") sudo bash "$SCRIPT_DIR/tools/1002xSUDO-installer.sh" ;; # ← korrekter Dateiname
  "10"|*) clear; exit ;;
esac
