#!/bin/bash

# Version erkennen
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
TARGET_DIR="$SCRIPT_DIR/../tools"
TMP_DIR="$HOME/.1002xtools_temp"
LOCAL_DEV_FILE="$SCRIPT_DIR/../dev.txt"

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

# Debug: Zeige Inhalt des Temp-Ordners
echo "Contents of $TMP_DIR:"
ls -l "$TMP_DIR"

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

whiptail --title "1002xTOOLS Updater" --infobox "Copying files to $TARGET_DIR ..." 8 50

# Alte .sh Dateien löschen im Zielordner (optional, aber sicher)
find "$TARGET_DIR" -type f -name "*.sh" -exec rm -f {} +

# Kopiere den kompletten Inhalt aus dem entpackten Ordner (das entspricht dem tools-Ordner im Repo)
cp -r "$EXTRACTED_DIR/"* "$TARGET_DIR/"

# Verschiebe debui.sh nach $SCRIPT_DIR/../ und setze Rechte
if [[ -f "$TARGET_DIR/debui.sh" ]]; then
  mv "$TARGET_DIR/debui.sh" "$SCRIPT_DIR/../debui.sh"
  chmod 777 "$SCRIPT_DIR/../debui.sh"
else
  whiptail --title "1002xTOOLS Updater" --msgbox "debui.sh not found in tools folder after copy." 10 50
fi

# Alle .sh im Zielordner ausführbar machen
find "$TARGET_DIR" -type f -name "*.sh" -exec chmod +x {} +

# Entferne "Licence" und dev.txt aus Zielordner falls vorhanden
find "$TARGET_DIR" -type f \( -iname "Licence" -o -iname "dev.txt" \) -exec rm -f {} +

# Aktualisierte Version speichern
echo "$REPO_VERSION" > "$LOCAL_DEV_FILE"

whiptail --title "1002xTOOLS Updater" --msgbox "Update completed successfully to version $REPO_VERSION." 10 50

rm -rf "$TMP_DIR"
rm "$SCRIPT_DIR/LICENSE"


# Exit Menü: Hauptmenü oder 1002xTOOLS beenden
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
