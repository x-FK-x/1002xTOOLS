#!/bin/bash

# === Variables ===
ZIP_URL="https://github.com"

# === Preparation ===
# Create a secure temporary directory
TMP_DIR=$(mktemp -d)
echo "[*] Created temp directory: $TMP_DIR"

# === Download ===
echo "[*] Downloading 1002xCMD..."
# Download directly into the temp folder
wget -q -O "$TMP_DIR/v0.5.zip" "$ZIP_URL"

if [ $? -ne 0 ]; then
  echo "[!] Download failed!"
  exit 1
fi

# === Extraction ===
echo "[*] Extracting archive..."
unzip -q "$TMP_DIR/v0.5.zip" -d "$TMP_DIR"

# Move into the directory to execute the files
cd "$TMP_DIR" || exit 1

# === Execution ===
if [[ -f "installer.sh" ]]; then
  echo "[*] Running installer..."
  chmod +x "installer.sh"
  sudo bash "installer.sh"
else
  echo "[!] Error: installer.sh not found in ZIP root!"
  ls -F
  exit 1
fi

# === Cleanup ===
echo "[*] Cleaning up..."
cd ~ # Leave the directory before deleting it
rm -rf "$TMP_DIR"

echo "[✓] 1002xCMD installation complete."
