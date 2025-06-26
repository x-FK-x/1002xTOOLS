#!/bin/bash

# === Variablen ===
TMP_DIR="/tmp/1002xSHELL_install_tmp"
ZIP_URL="https://github.com/x-FK-x/1002xSHELL/releases/download/v0.2/1002xSHELL-0.2.zip"
ZIP_FILE="$TMP_DIR/1002xSHELL-0.2.zip"

# === Vorbereiten ===
echo "[*] Creating temporary folder: $TMP_DIR"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# === Herunterladen ===
echo "[*] Downloading 1002xSHELL..."
wget -q -O "$ZIP_FILE" "$ZIP_URL"

if [[ $? -ne 0 || ! -f "$ZIP_FILE" ]]; then
  echo "[!] Failed to download archive from $ZIP_URL"
  exit 1
fi

# === Entpacken ===
echo "[*] Extracting archive..."
unzip -q "$ZIP_FILE" -d "$TMP_DIR"

EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "1002xSHELL*" | head -n 1)

if [[ ! -f "$EXTRACTED_DIR/installer.sh" ]]; then
  echo "[!] installer.sh not found in extracted folder."
  rm -rf "$TMP_DIR"
  exit 1
fi

# === Ausführen ===
echo "[*] Running installer..."
chmod +x "$EXTRACTED_DIR/installer.sh"
bash "$EXTRACTED_DIR/installer.sh"

# === Aufräumen ===
echo "[*] Cleaning up..."
rm -rf "$TMP_DIR"

echo "[✓] 1002xSHELL installation complete."
