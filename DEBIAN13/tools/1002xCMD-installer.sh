#!/bin/bash

# === Preparation ===
TMP_DIR=$(mktemp -d)
ZIP_URL="https://github.com"

# === Download (Using curl -L to follow GitHub redirects) ===
echo "[*] Downloading 1002xCMD..."
curl -s -L -o "$TMP_DIR/v0.5.zip" "$ZIP_URL"

# Check if file is empty (GitHub sometimes returns 0 bytes on 404)
if [[ ! -s "$TMP_DIR/v0.5.zip" ]]; then
  echo "[!] Download failed: File is empty or URL is unreachable."
  exit 1
fi

# === Extraction ===
echo "[*] Extracting archive..."
if ! unzip -q "$TMP_DIR/v0.5.zip" -d "$TMP_DIR"; then
    echo "[!] Extraction failed. The downloaded file might be corrupt."
    exit 1
fi

cd "$TMP_DIR" || exit 1

# === Execution ===
if [[ -f "installer.sh" ]]; then
  echo "[*] Running installer..."
  chmod +x installer.sh
  sudo ./installer.sh
else
  echo "[!] Error: installer.sh not found."
  ls -F
  exit 1
fi

# Cleanup
cd ~
rm -rf "$TMP_DIR"
