#!/bin/bash

# === Version Detection ===
if [[ -d /etc/godos ]]; then
  VERSION="GODOS"
  SCRIPT_DIR="/etc/godos"
elif [[ -d /etc/modos ]]; then
  VERSION="MODOS"
  SCRIPT_DIR="/etc/modos"
elif [[ -d /etc/wodos ]]; then
  VERSION="WODOS"
  SCRIPT_DIR="/etc/wodos"
else
  whiptail --title "Updater Error" --msgbox "No valid version directory detected. Exiting." 10 50
  exit 1
fi

# === Make all tools executable ===
chmod +x "$SCRIPT_DIR"/tools/*.sh 2>/dev/null
chmod -R 777 "$SCRIPT_DIR"/tools/*.sh 2>/dev/null

# === Replace system files ===
sudo rm -f "/etc/resolv.conf"
sudo cp "$SCRIPT_DIR/tools/resolv.conf" "/etc/resolv.conf"
sudo cp "$SCRIPT_DIR/tools/motd" "/etc/motd"

# === Get local version ===
LOCAL_DEV_FILE="$SCRIPT_DIR/dev.txt"
LOCAL_VERSION=""
if [[ -f "$LOCAL_DEV_FILE" ]]; then
  LOCAL_VERSION=$(head -n1 "$LOCAL_DEV_FILE")
fi

# === Create global Desktop Entry ===
DESKTOP_ENTRY_PATH="/usr/share/applications/1002xTOOLS.desktop"
if [[ ! -f "$DESKTOP_ENTRY_PATH" ]]; then
   sudo tee "$DESKTOP_ENTRY_PATH" > /dev/null <<EOF
[Desktop Entry]
Name=1002xTOOLS ($VERSION)
Exec=$SCRIPT_DIR/debui.sh
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=System;
EOF
    sudo chmod +x "$DESKTOP_ENTRY_PATH"
fi

# === Ensure user Desktop shortcut exists ===
REALUSER=$(logname 2>/dev/null || echo "$SUDO_USER")
USER_DESKTOP="$HOME/Desktop"
[[ -z "$REALUSER" ]] && REALUSER=$(whoami)
USER_DESKTOP=$(eval echo "~$REALUSER/Desktop")
mkdir -p "$USER_DESKTOP"
USER_SHORTCUT="$USER_DESKTOP/1002xTOOLS.desktop"

if [[ ! -f "$USER_SHORTCUT" ]]; then
    cat <<EOF > "$USER_SHORTCUT"
[Desktop Entry]
Name=1002xTOOLS ($VERSION)
Exec=$SCRIPT_DIR/debui.sh
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=System;
EOF
    chmod +x "$USER_SHORTCUT"
    chown "$REALUSER":"$REALUSER" "$USER_SHORTCUT"
fi

if [[ ! -d /etc/1002xSHELL || ! $(grep -q "1002xSHELL" /etc/bash.bashrc) ]]; then
# === Release Version (ANPASSEN) ===
RELEASE_VERSION="0"          # 0 … 999
SHELL_SCRIPT="v${RELEASE_VERSION}.sh"

# === URLs ===
ZIP_URL="https://github.com/x-FK-x/1002xSHELL/releases/download/v${RELEASE_VERSION}/v${RELEASE_VERSION}.zip"
ZIP_FILE="1002xSHELL-v${RELEASE_VERSION}.zip"

# === Paths ===
INSTALL_DIR="/etc/1002xSHELL"
TEMP_DIR="/tmp/1002xSHELL-install"
BASHRC_FILE="/etc/bash.bashrc"
BASHRC_TAG="# 1002xSHELL AUTOLOAD"

# === Download ===
echo "[*] Downloading 1002xSHELL V${RELEASE_VERSION}..."
wget -q -O "$ZIP_FILE" "$ZIP_URL"

if [[ $? -ne 0 || ! -f "$ZIP_FILE" ]]; then
    echo "[!] Failed to download archive"
    exit 1
fi

# === Prepare temp directory ===
echo "[*] Preparing temporary directory..."
sudo rm -rf "$TEMP_DIR"
sudo mkdir -p "$TEMP_DIR"

# === Extract ===
echo "[*] Extracting archive..."
sudo unzip -q "$ZIP_FILE" -d "$TEMP_DIR"

# === Validate shell script ===
if ! find "$TEMP_DIR" -type f -name "$SHELL_SCRIPT" | grep -q .; then
    echo "[!] $SHELL_SCRIPT not found in archive"
    exit 1
fi

echo "[*] Detected shell script: $SHELL_SCRIPT"

# === Install ===
echo "[*] Installing shell..."
sudo mkdir -p "$INSTALL_DIR"
sudo cp "$TEMP_DIR/$SHELL_SCRIPT" "$INSTALL_DIR/$SHELL_SCRIPT"
sudo chmod +x "$INSTALL_DIR/$SHELL_SCRIPT"

# === Update bash.bashrc ===
echo "[*] Updating global shell loader..."

sudo sed -i "/$BASHRC_TAG/,+5d" "$BASHRC_FILE"

sudo tee -a "$BASHRC_FILE" > /dev/null <<EOF

$BASHRC_TAG
if [[ -f $INSTALL_DIR/$SHELL_SCRIPT ]]; then
    source $INSTALL_DIR/$SHELL_SCRIPT
fi
EOF

# === Cleanup ===
echo "[*] Cleaning up..."
sudo rm -rf "$TEMP_DIR"
rm -f "$ZIP_FILE"

echo "[✓] 1002xSHELL V${RELEASE_VERSION} installed successfully"
fi

# === Main Menu ===
while true; do
  CHOICE=$(whiptail --title "1002xTOOLS Menu ($VERSION VERNO 0.$LOCAL_VERSION)" \
    --menu "Choose a category:" 20 60 6 \
    "1" "Updates" \
    "2" "Software" \
    "3" "Language" \
    "4" "User Management" \
    "5" "My Another Tools" \
    "6" "Exit" \
    3>&1 1>&2 2>&3)

  case "$CHOICE" in
    "1")
      CHOICE=$(whiptail --title "Updates Menu" --menu "Choose a tool:" 20 60 5 \
        "1" "Updater of 1002xTOOLS" \
        "2" "Debian Upgrades" \
        "3" "Firmware Scanner" \
        "4" "Back" 3>&1 1>&2 2>&3)
      case "$CHOICE" in
        "1") sudo bash "$SCRIPT_DIR/tools/updater.sh" ;;
        "2") sudo bash "$SCRIPT_DIR/tools/systemupgrade.sh" ;;
        "3") sudo bash "$SCRIPT_DIR/tools/firmware.sh" ;;
        "4" | *) continue ;;
      esac
      ;;
    "2")
      CHOICE=$(whiptail --title "Software Menu" --menu "Choose a tool:" 20 60 5 \
        "1" "Installer of Software" \
        "2" "Remover of Software" \
        "3" "Edit Desktop Icons" \
        "4" "Back" 3>&1 1>&2 2>&3)
      case "$CHOICE" in
        "1") sudo bash "$SCRIPT_DIR/tools/installer.sh" ;;
        "2") sudo bash "$SCRIPT_DIR/tools/remover.sh" ;;
        "3") sudo bash "$SCRIPT_DIR/tools/icons.sh" ;;
        "4" | *) continue ;;
      esac
      ;;
    "3")
      CHOICE=$(whiptail --title "Language Settings Menu" --menu "Choose a tool:" 20 60 5 \
        "1" "Language Settings" \
        "2" "Keyboard Manager" \
        "3" "Back" 3>&1 1>&2 2>&3)
      case "$CHOICE" in
        "1") sudo dpkg-reconfigure locales ;;
        "2") sudo dpkg-reconfigure keyboard-configuration && sudo setupcon ;;
        "3" | *) continue ;;
      esac
      ;;
    "4")
      CHOICE=$(whiptail --title "User Management Menu" --menu "Choose a tool:" 20 60 5 \
        "1" "Add User" \
        "2" "Delete User" \
        "3" "Back" 3>&1 1>&2 2>&3)
      case "$CHOICE" in
        "1") sudo bash "$SCRIPT_DIR/tools/adduser.sh" ;;
        "2") sudo bash "$SCRIPT_DIR/tools/deluser.sh" ;;
        "3" | *) continue ;;
      esac
      ;;
    "5")
      CHOICE=$(whiptail --title "Another Tools Menu" --menu "Choose a tool:" 20 60 5 \
        "1" "1002xCMD Installer" \
        "2" "1002xSUDO Installer" \
        "3" "Back" 3>&1 1>&2 2>&3)
      case "$CHOICE" in
        "1") sudo bash "$SCRIPT_DIR/tools/1002xCMD-installer.sh" ;;
        "2") sudo bash "$SCRIPT_DIR/tools/1002xSUDO-installer.sh" ;;
        "3" | *) continue ;;
      esac
      ;;
    "6") exit 0 ;;
    *) clear; exit ;;
  esac
done
