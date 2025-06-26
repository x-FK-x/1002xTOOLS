#!/bin/bash

# === Version erkennen ===
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
if [[ "$SCRIPT_DIR" == *"/godos"* ]]; then
  VERSION="godos"
elif [[ "$SCRIPT_DIR" == *"/modos"* ]]; then
  VERSION="modos"
elif [[ "$SCRIPT_DIR" == *"/todos"* ]]; then
  VERSION="sodos"
elif [[ "$SCRIPT_DIR" == *"/wodos"* ]]; then
  VERSION="wodos"
else
  whiptail --title "Updater Error" --msgbox "No valid version directory detected. Exiting." 10 50
  exit 1
fi

REPO="x-FK-x/1002xTOOLS"
BRANCH="$VERSION"
TARGET_DIR="$SCRIPT_DIR"
TMP_DIR="$HOME/.1002xTOOLS_temp"
LOCAL_DEV_FILE="$(dirname "$SCRIPT_DIR")/dev.txt"

mkdir -p "$TMP_DIR"

# === 1. Schritt: Selbst-Update: updater.sh neu laden ===
whiptail --title "Updater" --infobox "Downloading latest updater.sh..." 8 50

UPDATER_URL="https://raw.githubusercontent.com/$REPO/$BRANCH/tools/updater.sh"
UPDATER_NEW="$TMP_DIR/updater_new.sh"

wget -q -O "$UPDATER_NEW" "$UPDATER_URL"
if [[ $? -ne 0 ]] || [[ ! -s "$UPDATER_NEW" ]]; then
  whiptail --title "Updater Error" --msgbox "Failed to download updater.sh from $UPDATER_URL" 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

chmod +x "$UPDATER_NEW"

# Wenn neuer Updater anders als aktueller ist, ersetzen und neu starten
if ! cmp -s "$UPDATER_NEW" "$SCRIPT_DIR/updater.sh"; then
  whiptail --title "Updater" --infobox "Updating updater.sh and restarting..." 8 50
  cp "$UPDATER_NEW" "$SCRIPT_DIR/updater.sh"
  chmod +x "$SCRIPT_DIR/updater.sh"
  exec "$SCRIPT_DIR/updater.sh" "$@"
  exit 0
else
  whiptail --title "Updater" --infobox "Updater.sh is already up to date." 8 50
fi

# === 2. Schritt: Restliche Tools aktualisieren ===
whiptail --title "Updater" --infobox "Downloading tools archive..." 8 50

ZIP_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.zip"
ZIP_FILE="$TMP_DIR/$BRANCH.zip"

wget -q -O "$ZIP_FILE" "$ZIP_URL"
if [[ $? -ne 0 ]] || [[ ! -s "$ZIP_FILE" ]]; then
  whiptail --title "Updater Error" --msgbox "Failed to download $ZIP_URL" 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

whiptail --title "Updater" --infobox "Extracting archive..." 8 50

unzip -q -o "$ZIP_FILE" -d "$TMP_DIR"
if [[ $? -ne 0 ]]; then
  whiptail --title "Updater Error" --msgbox "Failed to extract archive." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

EXTRACTED_DIR="$TMP_DIR/1002xTOOLS-$BRANCH"

if [[ ! -d "$EXTRACTED_DIR/tools" ]]; then
  whiptail --title "Updater Error" --msgbox "Extracted tools folder not found." 10 50
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
  whiptail --title "Updater Error" --msgbox "No dev.txt found in repo. Cannot verify version. Aborting." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

if [[ "$LOCAL_VERSION" == "$REPO_VERSION" ]]; then
  whiptail --title "Updater" --msgbox "Tools are already up to date (version $LOCAL_VERSION)." 10 50
  rm -rf "$TMP_DIR"
  exit 0
fi

whiptail --title "Updater" --infobox "Copying updated files to tools/..." 8 50

# Kopiere Tools (überschreiben)
cp -r "$EXTRACTED_DIR/tools/"* "$SCRIPT_DIR/"

# debui.sh verschieben aus tools/ ins Hauptverzeichnis (z.B. /modos/debui.sh)
if [[ -f "$SCRIPT_DIR/debui.sh" ]]; then
  mv -f "$SCRIPT_DIR/debui.sh" "$(dirname "$SCRIPT_DIR")/"
  chmod 755 "$(dirname "$SCRIPT_DIR")/debui.sh"
fi

# Rechte setzen (tools/*.sh ausführbar machen)
chmod +x "$SCRIPT_DIR/"*.sh

# Alte dev.txt löschen und neue speichern
rm -f "$LOCAL_DEV_FILE"
cp "$EXTRACTED_DIR/dev.txt" "$LOCAL_DEV_FILE"

whiptail --title "Updater" --msgbox "Update completed successfully to version $REPO_VERSION." 10 50

rm -rf "$TMP_DIR"
exit 0
