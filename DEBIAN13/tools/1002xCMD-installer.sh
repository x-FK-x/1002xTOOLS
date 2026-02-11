#!/bin/bash

# Prüfen, ob als root ausgeführt
if [[ $EUID -ne 0 ]]; then
   echo "[!] Dieses Skript muss mit sudo ausgeführt werden."
   exit 1
fi

ZIP_URL="https://github.com/x-FK-x/1002xCMD/releases/download/v0.5/v0.5.zip"
TMP_DIR=$(mktemp -d) # Sicherer temporärer Ordner

# Download
echo "[*] Downloading..."
wget -q -O "$TMP_DIR/v0.5.zip" "$ZIP_URL" || exit 1

# Entpacken
echo "[*] Extracting..."
unzip -q "$TMP_DIR/v0.5.zip" -d "$TMP_DIR"

# Dynamisch den Ordner finden (GitHub zips haben oft den Namen des Repos + Version)
EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)

if [[ -z "$EXTRACTED_DIR" ]]; then
    echo "[!] Installations-Ordner nicht gefunden."
    rm -rf "$TMP_DIR"
    exit 1
fi

# Ausführen
chmod +x "$EXTRACTED_DIR/installer.sh"
bash "$EXTRACTED_DIR/installer.sh"

# Aufräumen
rm -rf "$TMP_DIR"
echo "[✓] Installation complete."
