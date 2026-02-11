#!/bin/bash

# ==============================================================================
# 1002xEASYCOMMAND Online Installer
# ==============================================================================
set -euo pipefail

VERSION="1.0"
# Dein Original-Link:
SCRIPT_URL="https://github.com/x-FK-x/1002xEASYCOMMAND/releases/download/1.0/install_1002xEASYCOMMAND.sh"

echo "========================================="
echo "   1002xEASYCOMMAND Online Installer v$VERSION"
echo "========================================="

# sudo prüfen
if ! sudo -v 2>/dev/null; then
    echo "[!] Dieses Skript benötigt sudo-Rechte."
    exit 1
fi

# Deinstallation
if [[ "${1:-}" == "uninstall" ]]; then
    echo "[*] Entferne 1002xEASYCOMMAND..."
    sudo rm -f /etc/profile.d/1002xEASYCOMMAND.sh
    sudo rm -f /etc/bash_completion.d/1002xEASYCOMMAND
    sudo sed -i '/1002xEASYCOMMAND/d' /etc/bash.bashrc
    echo "[✓] Entfernt."
    exit 0
fi

# Download in temporären Ordner (verhindert Datenmüll im aktuellen Verzeichnis)
TMP_FILE=$(mktemp /tmp/install_1002X.XXXXXXXX.sh)
trap 'rm -f "$TMP_FILE"' EXIT

echo "[*] Downloade: $SCRIPT_URL"
if ! wget -q -O "$TMP_FILE" "$SCRIPT_URL"; then
    echo "[!] Download fehlgeschlagen!"
    exit 1
fi

# Ausführung
chmod +x "$TMP_FILE"
echo "[*] Starte Installation..."
sudo bash "$TMP_FILE"

echo -e "\n[✓] Fertig! Bitte logge dich neu ein."
