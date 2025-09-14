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
TARGET_DIR="$SCRIPT_DIR/tools"
TMP_DIR="$HOME/.1002xtools_temp"
LOCAL_DEV_FILE="$SCRIPT_DIR/dev.txt"
FOLDER="V1"   # Ordner, der aus dem Repo extrahiert werden soll

mkdir -p "$TMP_DIR"
mkdir -p "$TARGET_DIR"

whiptail --title "1002xTOOLS Updater" --infobox "Downloading $BRANCH.zip archive..." 8 50

ZIP_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.zip"
ZIP_FILE="$TMP_DIR/$BRANCH.zip"

wget -q -O "$ZIP_FILE" "$ZIP_URL"
if [[ $? -ne 0 ]]; then
  whiptail --title "1002xTOOLS Updater" --msgbox "Failed to download $ZIP_URL" 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

whiptail --title "1002xTOOLS Updater" --infobox "Extracting archive..." 8 50
unzip -q -o "$ZIP_FILE" -d "$TMP_DIR"
if [[ $? -ne 0 ]]; then
  whiptail --title "1002xTOOLS Updater" --msgbox "Failed to extract archive." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

# Ordner im Temp-Verzeichnis ermitteln
EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "1002xTOOLS*" | head -n 1)
if [[ ! -d "$EXTRACTED_DIR" ]]; then
  whiptail --title "1002xTOOLS Updater" --msgbox "Extracted folder not found." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

# Versionen vergleichen
LOCAL_VERSION=""
REPO_VERSION=""

if [[ -f "$LOCAL_DEV_FILE" ]]; then
  LOCAL_VERSION=$(head -n1 "$LOCAL_DEV_FILE")
fi

if [[ -f "$EXTRACTED_DIR/dev.txt" ]]; then
  REPO_VERSION=$(head -n1 "$EXTRACTED_DIR/dev.txt")
else
  whiptail --title "1002xTOOLS Updater" --msgbox "No dev.txt found in repo. Cannot verify version. Aborting." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

if [[ "$LOCAL_VERSION" == "$REPO_VERSION" ]]; then
  whiptail --title "1002xTOOLS Updater" --msgbox "Tools are already up to date (version $LOCAL_VERSION)." 10 50
  rm -rf "$TMP_DIR"
  exit 0
fi

whiptail --title "1002xTOOLS Updater" --infobox "Copying $FOLDER to $TARGET_DIR ..." 8 50

# Nur den Unterordner V1 kopieren
if [[ -d "$EXTRACTED_DIR/$FOLDER" ]]; then
    # Alte .sh Dateien im Zielordner löschen
    find "$TARGET_DIR" -type f -name "*.sh" -exec rm -f {} +

    # Nur den Inhalt von V1 kopieren
    cp -r "$EXTRACTED_DIR/$FOLDER/"* "$TARGET_DIR/"

    # debui.sh verschieben und Rechte setzen, falls vorhanden
    if [[ -f "$TARGET_DIR/debui.sh" ]]; then
        mv "$TARGET_DIR/debui.sh" "$SCRIPT_DIR/debui.sh"
        chmod 777 "$SCRIPT_DIR/debui.sh"
    fi

    # Alle .sh im Zielordner ausführbar machen
    find "$TARGET_DIR" -type f -name "*.sh" -exec chmod +x {} +

    # "Licence" und dev.txt aus Zielordner entfernen
    find "$TARGET_DIR" -type f \( -iname "Licence" -o -iname "dev.txt" \) -exec rm -f {} +
else
    whiptail --title "1002xTOOLS Updater" --msgbox "Folder $FOLDER not found in the repo." 10 50
    rm -rf "$TMP_DIR"
    exit 1
fi

# Aktualisierte Version speichern
echo "$REPO_VERSION" > "$LOCAL_DEV_FILE"

whiptail --title "1002xTOOLS Updater" --msgbox "Update completed successfully to version $REPO_VERSION." 10 50

# Temp aufräumen
rm -rf "$TMP_DIR"
rm -f "$SCRIPT_DIR/LICENSE"

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
