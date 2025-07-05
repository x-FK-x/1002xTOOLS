#!/bin/bash

# === Variablen ===

ZIP_URL="https://github.com/x-FK-x/1002xCMD/releases/download/v0.2/1002xCMD-0.2.zip"
ZIP_FILE="1002xCMD-0.2.zip"


# === Herunterladen ===
echo "[*] Downloading 1002xCMD..."
wget -q -O "$ZIP_FILE" "$ZIP_URL"

if [[ $? -ne 0 || ! -f "$ZIP_FILE" ]]; then
  echo "[!] Failed to download archive from $ZIP_URL"
  exit 1
fi

# === Entpacken ===
echo "[*] Extracting archive..."
sudo mkdir /temp
sudo unzip -q "$ZIP_FILE" -d /temp

EXTRACTED_DIR=$(find /temp -maxdepth 1 -type d -name "1002xCMD*" | head -n 1)


# === Ausführen ===
echo "[*] Running installer..."
sudo chmod +x "$EXTRACTED_DIR/installer.sh"
sudo bash "$EXTRACTED_DIR/installer.sh"

# === Aufräumen ===
echo "[*] Cleaning up..."
sudo rm -rf /temp
sudo rm $ZIP_FILE

echo "[✓] 1002xCMD installation complete."
