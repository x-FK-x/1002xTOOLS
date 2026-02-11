#!/bin/bash

# ==========================================
# 1002xEASYCOMMAND Online Installer
# ==========================================

VERSION="1.0"
SCRIPT_URL="https://github.com"
SCRIPT_FILE="install_1002xEASYCOMMAND.sh"

echo "========================================="
echo "   1002xEASYCOMMAND Online Installer"
echo "========================================="

# Sudo-Rechte prüfen
if ! sudo -v 2>/dev/null; then
    echo "[!] This installer requires sudo privileges."
    exit 1
fi

# Uninstall-Logik
if [[ "$1" == "uninstall" ]]; then
    echo "[*] Removing 1002xEASYCOMMAND..."
    sudo rm -f /etc/profile.d/1002xEASYCOMMAND.sh
    sudo rm -f /etc/bash_completion.d/1002xEASYCOMMAND
    sudo sed -i '/1002xEASYCOMMAND/d' /etc/bash.bashrc
    echo "[✓] 1002xEASYCOMMAND removed."
    exit 0
fi

# Download in eine temporäre Datei
echo "[*] Downloading installer..."
wget -q -O "${SCRIPT_FILE}.raw" "$SCRIPT_URL"

if [[ $? -ne 0 || ! -f "${SCRIPT_FILE}.raw" ]]; then
    echo "[!] Failed to download installer from $SCRIPT_URL"
    exit 1
fi

# FIX: Windows-Zeilenumbrüche (CRLF) in Linux-Format (LF) umwandeln
# Das entfernt die Fehlermeldung: $'\r': command not found
tr -d '\r' < "${SCRIPT_FILE}.raw" > "$SCRIPT_FILE"
rm -f "${SCRIPT_FILE}.raw"

# Syntax-Check: Prüfen, ob das heruntergeladene Skript valide ist
if ! bash -n "$SCRIPT_FILE" 2>/dev/null; then
    echo "[!] Error: The downloaded script has syntax errors or is corrupted."
    rm -f "$SCRIPT_FILE"
    exit 1
fi

# Executable setzen
chmod +x "$SCRIPT_FILE"

# Installer ausführen
echo "[*] Running official installer..."
sudo bash "./$SCRIPT_FILE"

# Cleanup
rm -f "$SCRIPT_FILE"

echo
echo "[✓] 1002xEASYCOMMAND installation complete."
echo "Log out and back in to activate."
