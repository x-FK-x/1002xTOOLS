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

echo "Detected version: $VERSION"
echo "Script path: $SCRIPT_DIR"

# === Pfade definieren ===
REPO="x-FK-x/1002xTOOLS"
BRANCH="$VERSION"
TARGET_DIR="$SCRIPT_DIR/tools"
TMP_DIR="$HOME/.1002xTOOLS_temp"
LOCAL_DEV_FILE="$SCRIPT_DIR/dev.txt"

mkdir -p "$TMP_DIR"
mkdir -p "$TARGET_DIR"

whiptail --title "1002xTOOLS Updater" --infobox "Downloading $BRANCH.zip archive..." 8 50
ZIP_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.zip"
ZIP_FILE="$TMP_DIR/$BRANCH.zip"

echo "Downloading from: $ZIP_URL"
wget -O "$ZIP_FILE" "$ZIP_URL"
if [[ $? -ne 0 ]]; then
  whiptail --title "Updater Error" --msgbox "Download failed." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

# === Entpacken ===
whiptail --title "1002xTOOLS Updater" --infobox "Extracting archive..." 8 50
unzip -q -o "$ZIP_FILE" -d "$TMP_DIR"
if [[ $? -ne 0 ]]; then
  whiptail --title "Updater Error" --msgbox "Extraction failed." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

EXTRACTED_DIR="$TMP_DIR/1002xTOOLS-$BRANCH"
echo "Extracted to: $EXTRACTED_DIR"

# === Version vergleichen ===
if [[ -f "$SCRIPT_DIR/dev.txt" ]]; then
  LOCAL_VERSION=$(head -n1 "$SCRIPT_DIR/dev.txt")
else
  LOCAL_VERSION="none"
fi

if [[ -f "$EXTRACTED_DIR/dev.txt" ]]; then
  REPO_VERSION=$(head -n1 "$EXTRACTED_DIR/dev.txt")
else
  whiptail --title "Updater Error" --msgbox "dev.txt missing in repo." 10 50
  rm -rf "$TMP_DIR"
  exit 1
fi

echo "Local version: $LOCAL_VERSION"
echo "Repo  version: $REPO_VERSION"

if [[ "$LOCAL_VERSION" == "$REPO_VERSION" ]]; then
  whiptail --title "1002xTOOLS Updater" --msgbox "Already up to date (v$LOCAL_VERSION)." 10 50
  rm -rf "$TMP_DIR"
  exit 0
fi

# === Dateien kopieren ===
whiptail --title "1002xTOOLS Updater" --infobox "Copying tools to $TARGET_DIR ..." 8 50
cp -rv "$EXTRACTED_DIR/tools/"* "$TARGET_DIR/"

# === debui.sh in den Hauptordner verschieben ===
if [[ -f "$EXTRACTED_DIR/debui.sh" ]]; then
  echo "Copying debui.sh to $SCRIPT_DIR"
  mv -v "$EXTRACTED_DIR/debui.sh" "$SCRIPT_DIR/debui.sh"
  chmod 755 "$SCRIPT_DIR/debui.sh"
else
  echo "debui.sh not found in repo!"
fi

# === dev.txt aktualisieren ===
echo "$REPO_VERSION" > "$SCRIPT_DIR/dev.txt"

# === Tools ausführbar machen ===
chmod +x "$SCRIPT_DIR/tools/"*.sh 2>/dev/null

whiptail --title "1002xTOOLS Updater" --msgbox "Update to version $REPO_VERSION completed." 10 50

# === tmp aufräumen ===
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
    "2")
      exit 0
      ;;
    *)
      whiptail --msgbox "Invalid option." 8 40
      ;;
  esac
done
