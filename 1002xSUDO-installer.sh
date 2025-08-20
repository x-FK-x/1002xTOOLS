#!/bin/bash

whiptail --title "1002xTOOLS Error" --msgbox "Not yet available." 10 50

# === Rückkehrmenü ===
# === Rückkehrmenü ===
while true; do
  ACTION=$(whiptail --title "Installer finished" --menu "What do you want to do now?" 10 50 2 \
    "1" "Return to main menu" \
    "2" "Exit 1002xTOOLS" 3>&1 1>&2 2>&3)

  case "$ACTION" in
    "1")
      bash /etc/godos/debui.sh
      ;;
    "2")
      exit 0
      ;;
    *)
      whiptail --msgbox "Invalid option. Please choose again." 8 40
      ;;
  esac
done
