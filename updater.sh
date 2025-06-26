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
TARGET_DIR="$SCRIPT_DIR/tools"
TMP_DIR="$HOME/.1002xTOOLS_temp"

mkdir -p "$TMP_DIR"
mkdir -p "$TARGET_DIR"

whiptail --title "1002xTOOLS Updater" --infobox "Downloading $BRANCH.zip archive..." 8 50

ZIP_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.zip"
ZIP_FILE="$TMP_DIR/$BRANCH.zip"

wget -q -O "$ZIP_FILE" "$ZIP_URL"
if [[ $? -ne 0 ]]; then
  whiptail --title "Updater" --msgbox "Download failed from $ZIP_URL" 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

whiptail --title "Updater" --infobox "Extracting archive..." 8 50
unzip -q -o "$ZIP_FILE" -d "$TMP_DIR"
if [[ $? -ne 0 ]]; then
  whiptail --title "Updater" --msgbox "Failed to extract archive." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

EXTRACTED_DIR="$TMP_DIR/1002xTOOLS-$BRANCH"

if [[ ! -d "$EXTRACTED_DIR" ]]; then
  whiptail --title "Updater" --msgbox "Extracted directory not found!" 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

# === Version vergleichen ===
LOCAL_DEV_FILE="$SCRIPT_DIR/tools/dev.txt"
REPO_DEV_FILE="$EXTRACTED_DIR/tools/dev.txt"

LOCAL_VERSION=""
REPO_VERSION=""

[[ -f "$LOCAL_DEV_FILE" ]] && LOCAL_VERSION=$(head -n1 "$LOCAL_DEV_FILE")
[[ -f "$REPO_DEV_FILE" ]] && REPO_VERSION=$(head -n1 "$REPO_DEV_FILE")

if [[ "$LOCAL_VERSION" == "$REPO_VERSION" ]]; then
  whiptail --title "Updater" --msgbox "Already up to date (version $LOCAL_VERSION)." 10 50
  rm -rf "$TMP_DIR"
  exit 0
fi

whiptail --title "Updater" --infobox "Updating files..." 8 50

# === Kopiere Tools ===
cp -r "$EXTRACTED_DIR/tools/"* "$TARGET_DIR/"

# === Verschiebe debui.sh ===
if [[ -f "$EXTRACTED_DIR/tools/debui.sh" ]]; then
  mv -v "$EXTRACTED_DIR/tools/debui.sh" "$SCRIPT_DIR/../debui.sh"
  chmod 755 "$SCRIPT_DIR/debui.sh"
else
  echo "debui.sh not found in tools/!"
fi

# === Entferne Lizenz und dev.txt aus tools ===
rm -f "$TARGET_DIR/LICENSE"
rm -f "$TARGET_DIR/dev.txt"

# === dev.txt neu speichern ===
echo "$REPO_VERSION" > "$LOCAL_DEV_FILE"

# === Alle Skripte ausführbar machen ===
chmod +x "$SCRIPT_DIR/tools/"*.sh 2>/dev/null
chmod +x "$SCRIPT_DIR/debui.sh"

whiptail --title "Updater" --msgbox "Update to version $REPO_VERSION completed." 10 50
rm -rf "$TMP_DIR"

# === Menü nach Update ===
while true; do
  ACTION=$(whiptail --title "Updater finished" --menu "What do you want to do now?" 10 50 2 \
    "1" "Return to main menu" \
    "2" "Exit 1002xTOOLS" 3>&1 1>&2 2>&3)

  case $ACTION in
    "1")
      if [[ -x "$SCRIPT_DIR/debui.sh" ]]; then
        exec "$SCRIPT_DIR/debui.sh"
      else
        whiptail --msgbox "debui.sh not found or not executable!" 10 50
        exit 1
      fi
      ;;
    "2") exit 0 ;;
    *) whiptail --msgbox "Invalid option." 8 40 ;;
  esac
done
