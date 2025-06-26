#!/bin/bash

# === Detect version ===
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
TARGET_DIR="$SCRIPT_DIR/../tools"
TMP_DIR="$HOME/.1002xTOOLS_temp"
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

EXTRACTED_DIR="$TMP_DIR/1002xTOOLS-$BRANCH"

if [[ ! -d "$EXTRACTED_DIR" ]]; then
  whiptail --title "1002xTOOLS Updater" --msgbox "Extracted folder not found." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

# === Compare versions ===
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

whiptail --title "1002xTOOLS Updater" --infobox "Updating updater.sh script..." 8 50

# 1) Update updater.sh itself
UPDATER_OLD_HASH=""
UPDATER_NEW_HASH=""

if [[ -f "$SCRIPT_DIR/updater.sh" ]]; then
  UPDATER_OLD_HASH=$(sha256sum "$SCRIPT_DIR/updater.sh" | cut -d' ' -f1)
fi

if [[ -f "$EXTRACTED_DIR/tools/updater.sh" ]]; then
  cp "$EXTRACTED_DIR/tools/updater.sh" "$SCRIPT_DIR/updater.sh"
  chmod 777 "$SCRIPT_DIR/updater.sh"
else
  whiptail --title "1002xTOOLS Updater" --msgbox "updater.sh not found in ZIP tools folder!" 10 50
fi

UPDATER_NEW_HASH=$(sha256sum "$SCRIPT_DIR/updater.sh" | cut -d' ' -f1)

# Falls updater.sh sich geändert hat, Skript neu starten und beenden
if [[ "$UPDATER_OLD_HASH" != "$UPDATER_NEW_HASH" ]]; then
  whiptail --title "1002xTOOLS Updater" --msgbox "updater.sh wurde aktualisiert. Starte neu..." 8 50
  exec "$SCRIPT_DIR/updater.sh"
  exit 0
fi

whiptail --title "1002xTOOLS Updater" --infobox "Updating debui.sh..." 8 50

# 2) Update debui.sh in main version directory, chmod 777
if [[ -f "$EXTRACTED_DIR/debui.sh" ]]; then
  cp "$EXTRACTED_DIR/debui.sh" "$SCRIPT_DIR/debui.sh"
  chmod 777 "$SCRIPT_DIR/debui.sh"
else
  whiptail --title "1002xTOOLS Updater" --msgbox "debui.sh not found in ZIP root folder!" 10 50
fi

whiptail --title "1002xTOOLS Updater" --infobox "Copying other tools..." 8 50

# 3) Copy all other tool scripts, chmod 777
cp -r "$EXTRACTED_DIR/tools/"* "$TARGET_DIR/"
chmod 777 "$TARGET_DIR"/*.sh

# Clean up unwanted files from tools
rm -f "$TARGET_DIR/LICENSE"
rm -f "$TARGET_DIR/dev.txt"

# Update local dev.txt version file
echo "$REPO_VERSION" > "$LOCAL_DEV_FILE"

whiptail --title "1002xTOOLS Updater" --msgbox "Update completed successfully to version $REPO_VERSION." 10 50

rm -rf "$TMP_DIR"

# Exit menu
while true; do
  ACTION=$(whiptail --title "Updater finished" --menu "What do you want to do now?" 10 50 2 \
    "1" "Return to main menu" \
    "2" "Exit 1002xTOOLS" 3>&1 1>&2 2>&3)

  case $ACTION in
    "1")
      if [[ -x "$SCRIPT_DIR/debui.sh" ]]; then
        exec "$SCRIPT_DIR/debui.sh"
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
