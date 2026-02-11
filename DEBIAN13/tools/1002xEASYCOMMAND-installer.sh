#!/bin/bash

# ==========================================
# 1002xEASYCOMMAND Online Installer
# ==========================================

VERSION="1.0"
SCRIPT_URL="https://github.com/x-FK-x/1002xEASYCOMMAND/releases/download/1.0/install_1002xEASYCOMMAND.sh"
SCRIPT_FILE="install_1002xEASYCOMMAND.sh"

echo "========================================="
echo "   1002xEASYCOMMAND Online Installer"
echo "========================================="

# sudo prüfen
if ! sudo -v 2>/dev/null; then
    echo "[!] This installer requires sudo privileges."
    exit 1
fi

# uninstall support
if [[ "$1" == "uninstall" ]]; then
    echo "[*] Removing 1002xEASYCOMMAND..."
    sudo bash /etc/profile.d/1002xEASYCOMMAND.sh 2>/dev/null
    sudo rm -f /etc/profile.d/1002xEASYCOMMAND.sh
    sudo rm -f /etc/bash_completion.d/1002xEASYCOMMAND
    sudo sed -i '/1002xEASYCOMMAND/d' /etc/bash.bashrc
    echo "[✓] 1002xEASYCOMMAND removed."
    exit 0
fi

# Download
echo "[*] Downloading installer..."
wget -q -O "$SCRIPT_FILE" "$SCRIPT_URL"

if [[ $? -ne 0 || ! -f "$SCRIPT_FILE" ]]; then
    echo "[!] Failed to download installer."
    exit 1
fi

# Executable setzen
chmod +x "$SCRIPT_FILE"

# Installer ausführen
echo "[*] Running official installer..."
sudo bash "$SCRIPT_FILE"

# Cleanup
rm -f "$SCRIPT_FILE"

echo
echo "[✓] 1002xEASYCOMMAND installation complete."
echo "Log out and back in to activate."