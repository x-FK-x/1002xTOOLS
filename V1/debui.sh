#!/bin/bash

# === Version Detection ===
if [[ -d /etc/godos ]]; then
  VERSION="GODOS"
  SCRIPT_DIR="/etc/godos"
elif [[ -d /etc/modos ]]; then
  VERSION="MODOS"
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
sudo cp "$SCRIPT_DIR/tools/motd" "/etc/motd"


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

while true; do
  CHOICE=$(whiptail --title "1002xTOOLS Menu ($VERSION VERNO 1.$LOCAL_VERSION)" \
    --menu "Choose a category:" 20 60 6 \
    "1" "Updates" \
    "2" "Software" \
    "3" "Language" \
    "4" "User Management" \
    "5" "My Another Tools" \
    "6" "Exit" \
    3>&1 1>&2 2>&3)

  case "$CHOICE" in
    "1")
      # Updates Submenu
      CHOICE=$(whiptail --title "Updates Menu" \
        --menu "Choose a tool to launch:" 20 60 5 \
        "1" "Updater of 1002xTOOLS" \
        "2" "Debian Upgrades" \
        "3" "Firmware Installer" \
        "4" "Back" \
        3>&1 1>&2 2>&3)
      case "$CHOICE" in
        "1") sudo bash "$SCRIPT_DIR/tools/updater.sh" ;;
        "2") sudo bash "$SCRIPT_DIR/tools/systemupgrade.sh" ;;
        "3") sudo bash "$SCRIPT_DIR/tools/firmware.sh" ;;
        "4" | *) continue ;;  # Zurück ins Hauptmenü
      esac
      ;;
    "2")
      # Software Submenu
      CHOICE=$(whiptail --title "Software Menu" \
        --menu "Choose a tool to launch:" 20 60 5 \
        "1" "Installer of Software" \
        "2" "Remover of Software" \
        "3" "Back" \
        3>&1 1>&2 2>&3)
      case "$CHOICE" in
        "1") sudo bash "$SCRIPT_DIR/tools/installer.sh" ;;
        "2") sudo bash "$SCRIPT_DIR/tools/remover.sh" ;;
        "3" | *) continue ;;  # Zurück ins Hauptmenü
      esac
      ;;
    "3")
      # Language Settings Submenu
      CHOICE=$(whiptail --title "Language Settings Menu" \
        --menu "Choose a tool to launch:" 20 60 5 \
        "1" "Language Settings" \
        "2" "Keyboard Manager" \
        "3" "Back" \
        3>&1 1>&2 2>&3)
      case "$CHOICE" in
        "1") sudo dpkg-reconfigure locales ;;
        "2") sudo dpkg-reconfigure keyboard-configuration && sudo setupcon;;
        "3" | *) continue ;;  # Zurück ins Hauptmenü
      esac
      ;;
    "4")
      # User Management Submenu
      CHOICE=$(whiptail --title "User Management Menu" \
        --menu "Choose a tool to launch:" 20 60 5 \
        "1" "Add User" \
        "2" "Delete User" \
        "3" "Back" \
        3>&1 1>&2 2>&3)
      case "$CHOICE" in
        "1") sudo bash "$SCRIPT_DIR/tools/adduser.sh" ;;
        "2") sudo bash "$SCRIPT_DIR/tools/deluser.sh" ;;
        "3" | *) continue ;;  # Zurück ins Hauptmenü
      esac
      ;;
    "5")
      # My Another Tools Submenu
      CHOICE=$(whiptail --title "Another Tools Menu" \
        --menu "Choose a tool to launch:" 20 60 5 \
        "1" "1002xCMD Installer" \
        "2" "1002xSUDO Installer" \
        "3" "Back" \
        3>&1 1>&2 2>&3)
      case "$CHOICE" in
        "1") sudo bash "$SCRIPT_DIR/tools/1002xCMD-installer.sh" ;;
        "2") sudo bash "$SCRIPT_DIR/tools/1002xSUDO-installer.sh" ;;
        "3" | *) continue ;;  # Zurück ins Hauptmenü
      esac
      ;;
    "6")
      # Exit
      exit 0
      ;;
    *)
      clear
      exit
      ;;
  esac
done
#DODOS - DownTown1002xCollection of Debian OS
