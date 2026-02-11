#!/bin/bash

# ==========================================
# 1002xOPERATOR Extractor & Installer
# ==========================================

ZIP_URL="https://github.com/x-FK-x/1002xOPERATOR/archive/refs/heads/main.zip"
ZIP_FILE="1002xOPERATOR-main.zip"
TEMP_DIR="/tmp/1002xOPERATOR_extract"
INSTALL_DIR="/etc/1002xOPERATOR"
BASHRC="/etc/bash.bashrc"

echo "========================================="
echo "      1002xOPERATOR Installer"
echo "========================================="

# sudo prüfen
if ! sudo -v 2>/dev/null; then
    echo "[!] This script requires sudo privileges."
    exit 1
fi

# ==========================
# UNINSTALL
# ==========================
if [[ "$1" == "uninstall" ]]; then
    echo "[*] Removing 1002xOPERATOR..."
    sudo rm -rf "$INSTALL_DIR"
    sudo sed -i '/alias 1002xOPERATOR=/d' "$BASHRC"
    echo "[✓] 1002xOPERATOR removed and alias deleted."
    exit 0
fi

# ==========================
# DOWNLOAD
# ==========================
echo "[*] Downloading archive..."
wget -q -O "$ZIP_FILE" "$ZIP_URL"

if [[ $? -ne 0 || ! -f "$ZIP_FILE" ]]; then
    echo "[!] Failed to download archive."
    exit 1
fi

# ==========================
# EXTRACT
# ==========================
echo "[*] Extracting archive..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
unzip -q "$ZIP_FILE" -d "$TEMP_DIR"

EXTRACTED_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "1002xOPERATOR*" | head -n 1)

if [[ -z "$EXTRACTED_DIR" ]]; then
    echo "[!] Extraction failed."
    exit 1
fi

# ==========================
# COPY TO /etc
# ==========================
echo "[*] Copying to $INSTALL_DIR ..."
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo cp -r "$EXTRACTED_DIR"/* "$INSTALL_DIR"
sudo chmod -R 755 "$INSTALL_DIR"

# ==========================
# SET GLOBAL ALIAS
# ==========================
if ! grep -q "alias 1002xOPERATOR=" "$BASHRC"; then
    echo "alias 1002xOPERATOR='bash $INSTALL_DIR/menu.sh'" | sudo tee -a "$BASHRC" >/dev/null
    echo "[✓] Alias '1002xOPERATOR' added to $BASHRC"
fi

# ==========================
# CLEANUP
# ==========================
rm -rf "$TEMP_DIR"
rm -f "$ZIP_FILE"

echo
echo "[✓] 1002xOPERATOR installation complete."
echo "Installed to: $INSTALL_DIR"
echo "Log out and back in to activate the alias."
