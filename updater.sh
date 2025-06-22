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
LOCAL_DEV_FILE="$SCRIPT_DIR/../dev.txt"

mkdir -p "$TMP_DIR"
mkdir -p "$TARGET_DIR"

whiptail --title "XDOStools Updater" --infobox "Downloading $BRANCH-test.zip archive..." 8 50

ZIP_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH-test.zip"
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

# Versionen vergleichen
LOCAL_VERSION=""
REPO_VERSION=""

if [[ -f "$LOCAL_DEV_FILE" ]]; then
  LOCAL_VERSION=$(head -n1 "$LOCAL_DEV_FILE")
fi

if [[ -f "$EXTRACTED_DIR/dev.txt" ]]; then
  REPO_VERSION=$(head -n1 "$EXTRACTED_DIR/dev.txt")
else
  whiptail --title "XDOStools Updater" --msgbox "No dev.txt found in repo. Cannot verify version. Aborting." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

if [[ "$LOCAL_VERSION" == "$REPO_VERSION" ]]; then
  whiptail --title "XDOStools Updater" --msgbox "Tools are already up to date (version $LOCAL_VERSION)." 10 50
  rm -rf "$TMP_DIR"
  exit 0
fi

whiptail --title "XDOStools Updater" --infobox "Copying files to $TARGET_DIR ..." 8 50
cp -r "$EXTRACTED_DIR/"* "$TARGET_DIR/"

# Entferne alle "Licence" Dateien im Zielordner
rm /"$VERSION"/tools/LICENSE
rm /"$VERSION"/dev.txt

# Aktualisierte Version speichern
echo "$REPO_VERSION" > "$LOCAL_DEV_FILE"

whiptail --title "XDOStools Updater" --msgbox "Update completed successfully to version $REPO_VERSION." 10 50

rm -rf "$TMP_DIR"


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
