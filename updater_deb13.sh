#!/bin/bash

# === Ziel & Logfile ===
TARGET_TOOLS_DIR="/etc/godos/tools"
LOG_FILE="$TARGET_TOOLS_DIR/1002xTOOLS_updater.log"

mkdir -p "$TARGET_TOOLS_DIR"
echo "=== 1002xTOOLS Updater Log ===" > "$LOG_FILE"
echo "Start time: $(date)" >> "$LOG_FILE"

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

log "Starting updater..."

# === Whiptail prüfen ===
if ! command -v whiptail &> /dev/null; then
    log "Whiptail not installed. Installing..."
    sudo apt update && sudo apt install -y whiptail | tee -a "$LOG_FILE"
    command -v whiptail &> /dev/null || exit 1
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
    whiptail --msgbox "No valid version directory detected." 10 50
    exit 1
fi

OS_VERSION=$(head -n1 "$SCRIPT_DIR/tools/osversion.txt" 2>/dev/null)

if [[ "$OS_VERSION" != "DEBIAN13" ]]; then
    whiptail --msgbox "Unsupported OS version: $OS_VERSION" 10 50
    exit 0
fi

# === Repo & Temp ===
REPO="x-FK-x/1002xTOOLS"
BRANCH="$VERSION"
TMP_DIR="$HOME/.1002xtools_temp"
FOLDER="DEBIAN13"
LOCAL_DEV_FILE="$SCRIPT_DIR/dev.txt"

mkdir -p "$TMP_DIR"

ZIP_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.zip"
ZIP_FILE="$TMP_DIR/$BRANCH.zip"

log "Downloading $ZIP_URL"
wget -q -O "$ZIP_FILE" "$ZIP_URL" || exit 1

log "Extracting archive..."
unzip -q -o "$ZIP_FILE" -d "$TMP_DIR" || exit 1

EXTRACTED_ROOT=$(find "$TMP_DIR" -maxdepth 1 -type d -name "1002xTOOLS*" | head -n1)
EXTRACTED_DIR="$EXTRACTED_ROOT/$FOLDER"

[[ -d "$EXTRACTED_DIR" ]] || exit 1

# === Versionscheck ===
cp -f "$EXTRACTED_DIR/dev.txt" "$TMP_DIR/dev.txt"
REPO_VERSION=$(head -n1 "$TMP_DIR/dev.txt")
LOCAL_VERSION=$( [[ -f "$LOCAL_DEV_FILE" ]] && head -n1 "$LOCAL_DEV_FILE" )

if [[ "$LOCAL_VERSION" == "$REPO_VERSION" ]]; then
    whiptail --msgbox "Already up to date ($REPO_VERSION)" 10 50
    rm -rf "$TMP_DIR"
    exit 0
fi

cp -f "$TMP_DIR/dev.txt" "$LOCAL_DEV_FILE"

# === debui.sh ===
cp -f "$EXTRACTED_DIR/debui.sh" "$SCRIPT_DIR/debui.sh"
chmod +x "$SCRIPT_DIR/debui.sh"

# === motd ===
cp -f "$EXTRACTED_DIR/tools/motd" "$SCRIPT_DIR/tools/motd"

# === list.txt ===
cp -f "$EXTRACTED_DIR/tools/list.txt" "$SCRIPT_DIR/tools/list.txt"



# === 1002xSHELL-installer.sh (EXPLIZIT!) ===
if [[ -f "$EXTRACTED_DIR/tools/1002xSHELL-installer.sh" ]]; then
    cp -f "$EXTRACTED_DIR/tools/1002xSHELL-installer.sh" "$SCRIPT_DIR/tools/1002xSHELL-installer.sh"
    chmod +x "$SCRIPT_DIR/tools/1002xSHELL-installer.sh"
    log "Copied 1002xSHELL.sh explicitly to tools"
else
    log "1002xSHELL.sh not found in zip"
fi

# === Alle übrigen .sh aus tools ===
for file in "$EXTRACTED_DIR/tools/"*.sh; do
    [[ -f "$file" ]] || continue
    cp -f "$file" "$TARGET_TOOLS_DIR/"
    chmod +x "$TARGET_TOOLS_DIR/$(basename "$file")"
done

# === Globale Executable-Rechte ===
find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} +

# === Cleanup ===
rm -rf "$TMP_DIR"
rm -rf "$SCRIPT_DIR/tools/DEBIAN13"
rm -f "$SCRIPT_DIR/tools/LICENSE"

whiptail --msgbox "Update completed successfully to version $REPO_VERSION." 10 50
log "Update completed successfully."

# === Rückkehr ===
while true; do
    ACTION=$(whiptail --menu "Updater finished" 10 50 2 \
        "1" "Return to main menu" \
        "2" "Exit" 3>&1 1>&2 2>&3)
    case "$ACTION" in
        1) bash "$SCRIPT_DIR/debui.sh" ;;
        2) exit 0 ;;
    esac
done
