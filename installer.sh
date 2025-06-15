#!/bin/bash

# === Versionserkennung ===
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
if [[ "$SCRIPT_DIR" == *"/godos"* ]]; then
  VERSION="godos"
elif [[ "$SCRIPT_DIR" == *"/modos"* ]]; then
  VERSION="modos"
elif [[ "$SCRIPT_DIR" == *"/sodos"* ]]; then
  VERSION="sodos"
elif [[ "$SCRIPT_DIR" == *"/wodos"* ]]; then
  VERSION="wodos"
else
  whiptail --title "Installer Error" --msgbox "No valid version directory detected. Exiting." 10 50
  exit 1
fi

# === Programme zum Installieren (einfach erweitern) ===
PROGRAMS=(
  "vlc"
  "steam"
  "wine"
  "firefox-esr"
)

# Prüfe, ob whiptail installiert ist
if ! command -v whiptail &> /dev/null; then
  echo "Whiptail is not installed. Installing..."
  sudo apt update && sudo apt install -y whiptail
  if ! command -v whiptail &> /dev/null; then
    echo "Failed to install whiptail. Exiting."
    exit 1
  fi
fi

# Funktion: Hole Paketbeschreibung aus apt
get_description() {
  local pkg="$1"
  apt show "$pkg" 2>/dev/null | awk -F': ' '/^Description: / {print $2; exit}'
}

# Build menu items: ID + Beschreibung
MENU_ITEMS=()
for i in "${!PROGRAMS[@]}"; do
  pkg="${PROGRAMS[$i]}"
  desc=$(get_description "$pkg")
  MENU_ITEMS+=("$i" "$pkg - $desc")
done

# Hauptmenü
while true; do
  CHOICE=$(whiptail --title "Installer Menu ($VERSION)" --menu "Select software to install:" 20 70 10 "${MENU_ITEMS[@]}" "q" "Quit" 3>&1 1>&2 2>&3)
  if [[ "$CHOICE" == "q" || -z "$CHOICE" ]]; then
    break
  fi

  SELECTED_PKG="${PROGRAMS[$CHOICE]}"
  whiptail --title "Installer" --infobox "Installing $SELECTED_PKG ..." 8 50

  sudo apt update
  if sudo apt install -y "$SELECTED_PKG"; then
    whiptail --title "Installer" --msgbox "$SELECTED_PKG installed successfully." 10 50
  else
    whiptail --title "Installer" --msgbox "Failed to install $SELECTED_PKG." 10 50
  fi
done

# Exit Menü: Hauptmenü oder XDOStools beenden
while true; do
  ACTION=$(whiptail --title "Installer finished" --menu "What do you want to do now?" 10 50 2 \
    "1" "Return to main menu" \
    "2" "Exit XDOStools" 3>&1 1>&2 2>&3)

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
