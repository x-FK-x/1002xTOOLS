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

while true; do
  ACTION=$(whiptail --title "Updater finished" --menu "What do you want to do now?" 10 50 2 \
    "1" "Return to main menu" \
    "2" "Exit 1002xTOOLS" 3>&1 1>&2 2>&3)

  case $ACTION in
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
      whiptail --msgbox "Invalid option, please choose again." 8 40
      ;;
  esac
done
