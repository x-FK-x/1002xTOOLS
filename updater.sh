#!/bin/bash

# Version erkennen
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
  whiptail --title "Updater Error" --msgbox "No valid version directory detected. Exiting." 10 50
  exit 1
fi

REPO="x-FK-x/XDOStools"
BRANCH="$VERSION"
TARGET_DIR="$SCRIPT_DIR/../tools"
TMP_DIR="$HOME/.xdostools_temp"
DEV_FILE="$SCRIPT_DIR/../dev.txt"  # Pfad zur Datei mit Versionsinfo

mkdir -p "$TMP_DIR"
mkdir -p "$TARGET_DIR"

# Prüfen ob dev.txt existiert und ob Version schon aktuell ist
if [[ -f "$DEV_FILE" ]]; then
  INSTALLED_VERSION=$(head -n1 "$DEV_FILE")
  if [[ "$INSTALLED_VERSION" == "$VERSION" ]]; then
    whiptail --title "XDOStools Updater" --msgbox "Tools are already up to date for version '$VERSION'." 10 50
    exit 0
  fi
fi

whiptail --title "XDOStools Updater" --infobox "Downloading $BRANCH.zip archive..." 8 50

ZIP_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.zip"
ZIP_FILE="$TMP_DIR/$BRANCH.zip"

wget -q -O "$ZIP_FILE" "$ZIP_URL"
if [[ $? -ne 0 ]]; then
  whiptail --title "XDOStools Updater" --msgbox "Failed to download $ZIP_URL" 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

whiptail --title "XDOStools Updater" --infobox "Extracting archive..." 8 50
unzip -q -o "$ZIP_FILE" -d "$TMP_DIR"
if [[ $? -ne 0 ]]; then
  whiptail --title "XDOStools Updater" --msgbox "Failed to extract archive." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

EXTRACTED_DIR="$TMP_DIR/XDOStools-$BRANCH"

if [[ ! -d "$EXTRACTED_DIR" ]]; then
  whiptail --title "XDOStools Updater" --msgbox "Extracted folder not found." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

whiptail --title "XDOStools Updater" --infobox "Copying files to $TARGET_DIR ..." 8 50

# Liste der kopierten/überschriebenen Dateien für Reporting
UPDATED_FILES=()

# Kopieren, aber "Licence" ausschließen
while IFS= read -r -d '' file; do
  rel_path="${file#$EXTRACTED_DIR/}"
  if [[ "$rel_path" == "Licence" || "$rel_path" == "Licence" ]]; then
    continue
  fi
  dest="$TARGET_DIR/$rel_path"
  dest_dir=$(dirname "$dest")
  mkdir -p "$dest_dir"
  cp -f "$file" "$dest"
  UPDATED_FILES+=("$rel_path")
done < <(find "$EXTRACTED_DIR" -type f -print0)

# dev.txt aktualisieren
echo "$VERSION" > "$DEV_FILE"

# Reporting
if [ ${#UPDATED_FILES[@]} -eq 0 ]; then
  MESSAGE="No files updated."
else
  MESSAGE="Updated files:\n"
  for f in "${UPDATED_FILES[@]}"; do
    MESSAGE+="$f\n"
  done
fi

whiptail --title "XDOStools Updater" --msgbox "$MESSAGE" 15 60

rm -rf "$TMP_DIR"
exit 0
