#!/bin/bash

# === Prüfen ob whiptail installiert ist ===
if ! command -v whiptail &> /dev/null; then
  echo "Whiptail is not installed. Installing..."
  sudo apt update && sudo apt install -y whiptail
  if ! command -v whiptail &> /dev/null; then
    echo "Failed to install whiptail. Exiting."
    exit 1
  fi
fi

# === Version erkennen ===
if [[ -d /etc/godos ]]; then
  VERSION="godos"
  SCRIPT_DIR="/etc/godos"
elif [[ -d /etc/modos ]]; then
  VERSION="modos"
  SCRIPT_DIR="/etc/modos"
elif [[ -d /etc/wodos ]]; then
  VERSION="wodos"
  SCRIPT_DIR="/etc/wodos"
else
  whiptail --title "Updater Error" --msgbox "No valid version directory detected. Exiting." 10 50
  exit 1
fi

REPO="x-FK-x/1002xTOOLS"
BRANCH="$VERSION"
TMP_DIR="$HOME/.1002xtools_temp"
FOLDER="V1"
TARGET_TOOLS_DIR="$SCRIPT_DIR/tools"
LOCAL_DEV_FILE="$SCRIPT_DIR/dev.txt"

mkdir -p "$TMP_DIR"
mkdir -p "$TARGET_TOOLS_DIR"

whiptail --title "1002xTOOLS Updater" --infobox "Downloading $BRANCH.zip archive..." 8 50

ZIP_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.zip"
ZIP_FILE="$TMP_DIR/$BRANCH.zip"

wget -q -O "$ZIP_FILE" "$ZIP_URL"
if [[ $? -ne 0 ]]; then
  whiptail --title "1002xTOOLS Updater" --msgbox "Failed to download $ZIP_URL" 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

# Repo entpacken
whiptail --title "1002xTOOLS Updater" --infobox "Extracting archive..." 8 50
unzip -q -o "$ZIP_FILE" -d "$TMP_DIR"
if [[ $? -ne 0 ]]; then
  whiptail --title "1002xTOOLS Updater" --msgbox "Failed to extract archive." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

# Root-Verzeichnis des entpackten Repos
EXTRACTED_ROOT=$(find "$TMP_DIR" -maxdepth 1 -type d -name "1002xTOOLS*" | head -n1)
if [[ ! -d "$EXTRACTED_ROOT" ]]; then
 # whiptail --title "1002xTOOLS Updater" --msgbox "Extracted repo folder not found." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

# Ordner V1
EXTRACTED_DIR="$EXTRACTED_ROOT/$FOLDER"
if [[ ! -d "$EXTRACTED_DIR" ]]; then
  whiptail --title "1002xTOOLS Updater" --msgbox "Folder $FOLDER not found in the repo." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

# dev.txt aus Temp kopieren für Versionscheck
TMP_DEV_FILE="$TMP_DIR/dev.txt"
cp -f "$EXTRACTED_DIR/dev.txt" "$TMP_DEV_FILE"

# Versionsprüfung
REPO_VERSION=$(head -n1 "$TMP_DEV_FILE")
LOCAL_VERSION=$( [[ -f "$LOCAL_DEV_FILE" ]] && head -n1 "$LOCAL_DEV_FILE" || echo "" )

if [[ "$LOCAL_VERSION" == "$REPO_VERSION" ]]; then
  whiptail --title "1002xTOOLS Updater" --msgbox "Tools are already up to date (version $LOCAL_VERSION)." 10 50
  rm -rf "$TMP_DIR"
  exit 0
fi

# --- Dateien kopieren ---
# dev.txt nach SCRIPT_DIR
cp -f "$TMP_DEV_FILE" "$LOCAL_DEV_FILE"

# debui.sh nach SCRIPT_DIR
if [[ -f "$EXTRACTED_DIR/debui.sh" ]]; then
  cp -f "$EXTRACTED_DIR/debui.sh" "$SCRIPT_DIR/debui.sh"
else
  whiptail --title "1002xTOOLS Updater" --msgbox "debui.sh not found in V1." 10 50
fi

# Alle anderen .sh-Dateien nach tools kopieren (debui.sh und dev.txt ausgeschlossen)
mkdir -p "$TARGET_TOOLS_DIR"
for file in "$EXTRACTED_DIR"/*.sh; do
    filename=$(basename "$file")
    if [[ "$filename" != "debui.sh" ]]; then
        cp -u "$file" "$TARGET_TOOLS_DIR/"
    fi
done

# Alle .sh im Ziel ausführbar machen
find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} +

# Alias für alle User setzen
ALIAS_LINE='alias 1002xTOOLS="sudo bash '"$SCRIPT_DIR"'/debui.sh"'
if ! grep -Fxq "$ALIAS_LINE" /etc/bash.bashrc; then
    echo "$ALIAS_LINE" | sudo tee -a /etc/bash.bashrc >/dev/null
fi

# Cleanup
rm -rf "$TMP_DIR"

whiptail --title "1002xTOOLS Updater" --msgbox "Update completed successfully to version $REPO_VERSION." 10 50

# === Rückkehrmenü ===
while true; do
  ACTION=$(whiptail --title "Updater finished" --menu "What do you want to do now?" 10 50 2 \
    "1" "Return to main menu" \
    "2" "Exit 1002xTOOLS" 3>&1 1>&2 2>&3)

  case "$ACTION" in
    "1")
      bash "$SCRIPT_DIR/debui.sh"
      ;;
    "2")
      exit 0
      ;;
    *)
      whiptail --msgbox "Invalid option. Please choose again." 8 40
      ;;
  esac
done
