#!/bin/bash

# Logfile im tools-Ordner
TARGET_TOOLS_DIR="/etc/modos/tools"
LOG_FILE="$TARGET_TOOLS_DIR/1002xTOOLS_updater.log"

mkdir -p "$TARGET_TOOLS_DIR"
echo "=== 1002xTOOLS Updater Log ===" > "$LOG_FILE"
echo "Start time: $(date)" >> "$LOG_FILE"

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

log "Starting updater..."

# === Prüfen ob whiptail installiert ist ===
if ! command -v whiptail &> /dev/null; then
    log "Whiptail not installed. Installing..."
    sudo apt update && sudo apt install -y whiptail | tee -a "$LOG_FILE"
    if ! command -v whiptail &> /dev/null; then
        log "Failed to install whiptail. Exiting."
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
    log "No valid version directory detected. Exiting."
    whiptail --title "Updater Error" --msgbox "No valid version directory detected. Exiting." 10 50
    exit 1
fi

log "Detected version: $VERSION, SCRIPT_DIR: $SCRIPT_DIR"
OS_VERSION=$(head -n1 "/etc/modos/tools/osversion.txt")
echo "$OS_VERSION"
log "OS version: $OS_VERSION"

if [ "$OS_VERSION" = "DEBIAN13" ]; then
    log "DEBIAN 13 0"
    whiptail --title "Updater" --msgbox "DEBIAN13 installed. Continue." 10 50
elif [ "$OS_VERSION" = "DEBIAN14" ]; then
    log "DEBIAN 14"
  elif [ "$OS_VERSION" = "DEBIAN15" ]; then
    log "DEBIAN 15"
else
    log "Unkown Version: $OS_VERSION"
    exit 0
fi



# === Repo & Temp ===
REPO="x-FK-x/1002xTOOLS"
BRANCH="$VERSION"
TMP_DIR="$HOME/.1002xtools_temp"
FOLDER="DEBIAN13"
LOCAL_DEV_FILE="$SCRIPT_DIR/dev.txt"

mkdir -p "$TMP_DIR"

log "Downloading branch $BRANCH from repo $REPO..."
ZIP_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.zip"
ZIP_FILE="$TMP_DIR/$BRANCH.zip"

wget -q -O "$ZIP_FILE" "$ZIP_URL"
if [[ $? -ne 0 ]]; then
    log "Failed to download $ZIP_URL"
    whiptail --title "Updater" --msgbox "Failed to download $ZIP_URL" 10 50
    rm -rf "$TMP_DIR"
    exit 1
fi
log "Downloaded zip to $ZIP_FILE"

# Repo entpacken
log "Extracting archive..."
unzip -q -o "$ZIP_FILE" -d "$TMP_DIR"
if [[ $? -ne 0 ]]; then
    log "Failed to extract archive."
    whiptail --title "Updater" --msgbox "Failed to extract archive." 10 50
    rm -rf "$TMP_DIR"
    exit 1
fi

EXTRACTED_ROOT=$(find "$TMP_DIR" -maxdepth 1 -type d -name "1002xTOOLS*" | head -n1)
if [[ ! -d "$EXTRACTED_ROOT" ]]; then
    log "Extracted repo folder not found."
    whiptail --title "Updater" --msgbox "Extracted repo folder not found." 10 50
    rm -rf "$TMP_DIR"
    exit 1
fi
log "Extracted root: $EXTRACTED_ROOT"

EXTRACTED_DIR="$EXTRACTED_ROOT/$FOLDER"
if [[ ! -d "$EXTRACTED_DIR" ]]; then
    log "Folder $FOLDER not found in the repo."
    whiptail --title "Updater" --msgbox "Folder $FOLDER not found in the repo." 10 50
    rm -rf "$TMP_DIR"
    exit 1
fi
log "Using folder: $EXTRACTED_DIR"

# Versionscheck
if [[ -f "$EXTRACTED_DIR/dev.txt" ]]; then
    cp -f "$EXTRACTED_DIR/dev.txt" "$TMP_DIR/dev.txt"
    REPO_VERSION=$(head -n1 "$TMP_DIR/dev.txt")
    log "Repo version: $REPO_VERSION"
else
    log "dev.txt not found in folder."
    whiptail --title "Updater" --msgbox "dev.txt not found in DEBIAN13 folder." 10 50
    rm -rf "$TMP_DIR"
    exit 1
fi



LOCAL_VERSION=$( [[ -f "$LOCAL_DEV_FILE" ]] && head -n1 "$LOCAL_DEV_FILE" || echo "" )
log "Local version: $LOCAL_VERSION"

if [[ "$LOCAL_VERSION" == "$REPO_VERSION" ]]; then
    log "Tools are already up to date."
    whiptail --title "Updater" --msgbox "Tools are already up to date (version $OS_VERSION.$LOCAL_VERSION)." 10 50
    rm -rf "$TMP_DIR"
    exit 0
fi

# --- Dateien kopieren ---
# dev.txt
cp -f "$TMP_DIR/dev.txt" "$LOCAL_DEV_FILE"
log "Copied dev.txt to $LOCAL_DEV_FILE"

# debui.sh 
if [[ -f "$EXTRACTED_DIR/debui.sh" ]]; then
    cp -f "$EXTRACTED_DIR/debui.sh" "$SCRIPT_DIR/debui.sh.sh"
    chmod +x "$SCRIPT_DIR/debui.sh"
    log "Copied DEBIANui.sh to $SCRIPT_DIR/debui.sh"
else
    log "DEBIANui.sh not found in folder."
    whiptail --title "Updater" --msgbox "debui.sh not found in folder." 10 50
fi

# motd 
if [[ -f "$EXTRACTED_DIR/tools/motd" ]]; then
    cp -f "$EXTRACTED_DIR/tools/motd" "$SCRIPT_DIR/tools/motd"
       log "Copied motd to $SCRIPT_DIR/tools/motd"
else
    log "motd not found in folder."
    whiptail --title "Updater" --msgbox "motd not found in folder." 10 50
fi

# osversion 
if [[ -f "$EXTRACTED_DIR/tools/1002xSHELL-installer.sh" ]]; then
    cp -f "$EXTRACTED_DIR/tools/1002xSHELL-installer.sh" "$SCRIPT_DIR/tools/1002xSHELL-installer.sh"
    log "Copied 1002xSHELL-installer.sh to $SCRIPT_DIR/tools/1002xSHELL-installer.sh"
else
    log "1002xSHELL-installer.sh not found in folder."
    whiptail --title "Updater" --msgbox "1002xSHELL-installer.sh not found in folder." 10 50
fi

# list 
if [[ -f "$EXTRACTED_DIR/tools/list.txt" ]]; then
    cp -f "$EXTRACTED_DIR/tools/list.txt" "$SCRIPT_DIR/tools/list.txt"
    log "Copied list.txt to $SCRIPT_DIR/tools/list.txt"
else
    log "osversion.txt not found in folder."
    whiptail --title "Updater" --msgbox "osversion.txt not found in folder." 10 50
fi




# Alle .sh-Dateien aus DEBIAN13/tools nach tools kopieren
if [[ -d "$EXTRACTED_DIR/tools" ]]; then
    for file in "$EXTRACTED_DIR/tools/"*.sh; do
        [ -f "$file" ] || continue
        cp -f "$file" "$TARGET_TOOLS_DIR/"
        chmod +x "$TARGET_TOOLS_DIR/$(basename "$file")"
        log "Copied $file to $TARGET_TOOLS_DIR/"
    done
else
    log "No tools folder found in DEBIAN13"
fi

# Alle .sh im Ziel ausführbar machen
find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} +

# Alias für alle User setzen
ALIAS_LINE='alias 1002xUPDATES="sudo bash '"$SCRIPT_DIR"'/tools/updater.sh"'
if ! grep -Fxq "$ALIAS_LINE" /etc/bash.bashrc; then
    echo "$ALIAS_LINE" | sudo tee -a /etc/bash.bashrc >/dev/null
    log "Alias added to /etc/bash.bashrc"
fi

ALIAS_LINE2='alias 1002xTOOLS="sudo bash '"$SCRIPT_DIR"'/DEBIANui.sh"'
if ! grep -Fxq "$ALIAS_LINE2" /etc/bash.bashrc; then
    echo "$ALIAS_LINE2" | sudo tee -a /etc/bash.bashrc >/dev/null
    log "Alias added to /etc/bash.bashrc"
fi
ALIAS_LINE3='alias 1002xDNS="sudo rm /etc/resolv.conf && sudo cp '"$SCRIPT_DIR"'/tools/resolv.conf /etc"'
if ! grep -Fxq "$ALIAS_LINE3" /etc/bash.bashrc; then
    echo "$ALIAS_LINE3" | sudo tee -a /etc/bash.bashrc >/dev/null
    log "Alias added to /etc/bash.bashrc"
fi
# Cleanup
rm -rf "$TMP_DIR"
log "Temporary files cleaned."
rm "$SCRIPT_DIR/tools/LICENSE"
rm -r "$SCRIPT_DIR/tools/DEBIAN13"

whiptail --title "1002xTOOLS Updater" --msgbox "Update completed successfully to version $REPO_VERSION." 10 50
log "Update completed successfully to version $REPO_VERSION."

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

#DODOS - DownTown1002xCollection of DEBIANian OS
