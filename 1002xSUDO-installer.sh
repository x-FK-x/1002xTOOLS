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

whiptail --title "1002xTOOLS Error" --msgbox "Not yet available." 10 50

# === Rückkehrmenü ===
while true; do
  ACTION=$(whiptail --title "Installer finished" --menu "What do you want to do now?" 10 50 2 \
    "1" "Return to main menu" \
    "2" "Exit 1002xTOOLStools" 3>&1 1>&2 2>&3)

  case "$ACTION" in
    "1")
      PARENT_DIR=$(dirname "$SCRIPT_DIR")
      if [[ -x "$PARENT_DIR/debui.sh" ]]; then
        exec "$PARENT_DIR/debui.sh"
      else
        whiptail --msgbox "Main menu script debui.sh not found or not executable!" 10 50
        exit 1
      fi
      ;;
    "2")
      exit 0
      ;;
    *)
      whiptail --msgbox "Invalid option. Please choose again." 8 40
      ;;
  esac
done
