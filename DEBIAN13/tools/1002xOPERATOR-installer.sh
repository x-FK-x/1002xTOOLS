#!/bin/bash

# ==========================================
# 1002xOPERATOR Extractor & Installer (CURL FIX)
# ==========================================

ZIP_URL="https://github.com"
ZIP_FILE="/tmp/1002xOPERATOR-main.zip"
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
# DOWNLOAD WITH CURL
# ==========================
echo "[*] Downloading archive via curl..."
# -L folgt Redirects, -s für Silent (entfernt für Fehlersuche falls nötig)
sudo curl -L "$ZIP_URL" -o "$ZIP_FILE"

if [[ $? -ne 0 || ! -s "$ZIP_FILE" ]]; then
    echo "[!] Download failed. Please check your internet connection."
    exit 1
fi

# ==========================
# EXTRACT
# ==========================
echo "[*] Extracting archive..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
unzip -q "$ZIP_FILE" -d "$TEMP_DIR"

if [[ $? -ne 0 ]]; then
    echo "[!] Extraction failed. The zip file might be corrupt."
    rm -f "$ZIP_FILE"
    exit 1
fi

# Unterordner identifizieren (z.B. 1002xOPERATOR-main)
EXTRACTED_SUBDIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "1002xOPERATOR*" | head -n 1)

# ==========================
# COPY TO /etc (FLAT COPY)
# ==========================
echo "[*] Copying files to $INSTALL_DIR ..."
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"

# Wechselt in den Unterordner und kopiert den Inhalt direkt nach /etc/1002xOPERATOR
cd "$EXTRACTED_SUBDIR" || exit 1
sudo cp -rf . "$INSTALL_DIR/"

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
if [[ -f "$INSTALL_DIR/menu.sh" ]]; then
    echo "[✓] 1002xOPERATOR installation complete."
    echo "-----------------------------------------"
    echo "Location: $INSTALL_DIR/menu.sh"
    echo "-----------------------------------------"
    echo "Run 'source $BASHRC' or log in again to use the alias."
else
    echo "[!] ERROR: menu.sh was not found in $INSTALL_DIR after copy."
fi
