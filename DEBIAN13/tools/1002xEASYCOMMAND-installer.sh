#!/bin/bash

# ==============================================================================
# 1002xEASYCOMMAND Installer v2.1 (With Auto-Fix for Windows CRLF)
# ==============================================================================

# AUTO-FIX: Check for Windows line endings (\r) and fix them before continuing
if grep -q $'\r' "$0"; then
    echo "[!] Windows line endings detected. Fixing script format..."
    sed -i 's/\r$//' "$0"
    exec bash "$0" "$@"
fi

set -euo pipefail

VERSION="2.1"
MAIN_FILE="/etc/profile.d/1002xEASYCOMMAND.sh"
BASHRC="/etc/bash.bashrc"
LOG_FILE="/var/log/1002xEASYCOMMAND.log"

# Check sudo privileges using the standard [sudo-v](https://man7.org) command
if ! sudo -v 2>/dev/null; then
    echo "[!] This script requires sudo privileges."
    exit 1
fi

# =============================
# UNINSTALL LOGIC
# =============================
if [[ "${1:-}" == "uninstall" ]]; then
    echo "[*] Removing 1002xEASYCOMMAND..."
    sudo rm -f "$MAIN_FILE" "$LOG_FILE"
    sudo sed -i '/1002xEASYCOMMAND/d' "$BASHRC"
    echo "[✓] Successfully removed."
    exit 0
fi

# Initialize Logfile (Root-owned, world-writable for alias logging)
sudo touch "$LOG_FILE"
sudo chmod 666 "$LOG_FILE"

# =============================
# GENERATE MAIN RUNTIME FILE
# =============================
# Using <<'EOF' to prevent local shell variable expansion during installation
sudo tee "$MAIN_FILE" > /dev/null <<'EOF'
# =====================================================
# 1002xEASYCOMMAND Runtime Environment
# =====================================================

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
RESET="\e[0m"

LOG() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /var/log/1002xEASYCOMMAND.log 2>/dev/null || true
}

# Reliability checks based on [Debian Package Management](https://www.debian.org)
has_cmd() { command -v "$1" >/dev/null 2>&1; }
has_pkg() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed"; }
has_service() { systemctl list-unit-files "$1.service" 2>/dev/null | grep -q "enabled\|disabled" ; }

1002xEASYCOMMAND() {
    clear
    echo -e "${BLUE}========== 1002xEASYCOMMAND v2.1 ==========${RESET}"

    echo -e "${GREEN}SYSTEM:${RESET}   POWEROFF REBOOT SHUTDOWN"
    echo -e "${GREEN}PACKAGE:${RESET}  UPDATE UPGRADE INSTALL REMOVE APTSEARCH"

    if has_cmd ping; then echo -e "${GREEN}NETWORK:${RESET}  PING IP"; fi

    if has_pkg ufw; then echo -e "${GREEN}FIREWALL:${RESET} UFWSTATUS OPEN80 OPEN443 OPENSSH"; fi

    if has_service apache2 || has_service nginx; then
        echo -e "${GREEN}WEBSERVER:${RESET} WEBSTART WEBSTOP WEBRESTART"
    fi

    if has_cmd nmap || has_cmd msfconsole; then
        echo -e "${GREEN}SECURITY:${RESET}  NMAP METASPLOIT WIRESHARK SQLMAP"
    fi

    echo -e "\nType ${BLUE}EASYHELP${RESET} for information"
}

# Command Aliases with Logging
alias POWEROFF='LOG "POWEROFF"; sudo poweroff'
alias REBOOT='LOG "REBOOT"; sudo reboot'
alias SHUTDOWN='LOG "SHUTDOWN"; sudo shutdown now'

alias UPDATE='LOG "APT_UPDATE"; sudo apt update'
alias UPGRADE='sudo apt upgrade -y'
alias INSTALL='sudo apt install'
alias REMOVE='sudo apt remove --purge'
alias APTSEARCH='apt search'
alias APTCLEAN='apt autoclean && apt autoremove -y"
alias PING='ping -c 4'
alias IP='ip a'

alias UFWSTATUS='sudo ufw status verbose'
alias OPEN80='sudo ufw allow 80'
alias OPEN443='sudo ufw allow 443'
alias OPENSSH='sudo ufw allow 22'

# Webserver handling (Prioritizing Nginx)
if has_service nginx; then
    alias WEBSTART='sudo systemctl start nginx'
    alias WEBSTOP='sudo systemctl stop nginx'
    alias WEBRESTART='sudo systemctl restart nginx'
elif has_service apache2; then
    alias WEBSTART='sudo systemctl start apache2'
    alias WEBSTOP='sudo systemctl stop apache2'
    alias WEBRESTART='sudo systemctl restart apache2'
fi

alias NMAP='sudo nmap'
alias METASPLOIT='sudo msfconsole'
alias WIRESHARK='sudo wireshark'
alias SQLMAP='sqlmap'

EASYHELP() {
    echo "1002xEASYCOMMAND v2.1 Hub"
    echo "Usage: Simply type the commands listed in CAPITAL letters."
    echo "Check logs at: /var/log/1002xEASYCOMMAND.log"
}
EOF

sudo chmod 644 "$MAIN_FILE"

# =============================
# PERSISTENCE (BASHRC)
# =============================
if ! grep -q "1002xEASYCOMMAND" "$BASHRC"; then
    echo "source $MAIN_FILE" | sudo tee -a "$BASHRC" >/dev/null
    echo "alias 1002xEASYCOMMAND='1002xEASYCOMMAND'" | sudo tee -a "$BASHRC" >/dev/null
fi
source /etc/bash.bashrc
echo "[✓] Installation successful."
echo "Please run 'source /etc/bash.bashrc' or log out and back in."
