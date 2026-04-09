#!/bin/bash

# ==============================================================================
# 1002xEASYCOMMAND Installer v2.2 (KORRIGIERT & VERBESSERT)
# ==============================================================================

# AUTO-FIX: Check for Windows line endings (\r) and fix them before continuing
if grep -q $'\r' "$0"; then
    echo "[!] Windows line endings detected. Fixing script format..."
    sed -i 's/\r$//' "$0"
    exec bash "$0" "$@"
fi

set -euo pipefail

VERSION="2.2"
MAIN_FILE="/etc/profile.d/1002xEASYCOMMAND.sh"
BASHRC="/etc/bash.bashrc"
LOG_FILE="/var/log/1002xEASYCOMMAND.log"

# Check sudo privileges using the standard sudo -v command
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

# Initialize Logfile (Root-owned, restricted permissions for security)
sudo touch "$LOG_FILE"
sudo chmod 640 "$LOG_FILE"

# =============================
# GENERATE MAIN RUNTIME FILE
# =============================
# Using <<'EOF' to prevent local shell variable expansion during installation
sudo tee "$MAIN_FILE" > /dev/null <<'EOF'
# =====================================================
# 1002xEASYCOMMAND Runtime Environment v2.2
# =====================================================

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
YELLOW="\e[33m"
RESET="\e[0m"

LOG() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /var/log/1002xEASYCOMMAND.log
}

# Reliability checks based on standard command availability
has_cmd() { command -v "$1" >/dev/null 2>&1; }
has_pkg() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed"; }
has_service() { systemctl is-enabled "$1.service" >/dev/null 2>&1 || systemctl is-active "$1.service" >/dev/null 2>&1; }

1002xEASYCOMMAND() {
    clear
    echo -e "${BLUE}========== 1002xEASYCOMMAND v2.2 ==========${RESET}"
    echo ""

    echo -e "${GREEN}SYSTEM:${RESET}   POWEROFF REBOOT SHUTDOWN"
    echo -e "${GREEN}PACKAGE:${RESET}  UPDATE UPGRADE INSTALL REMOVE APTSEARCH APTCLEAN"

    if has_cmd ping; then 
        echo -e "${GREEN}NETWORK:${RESET}  PING IP"
    fi

    if has_pkg ufw; then 
        echo -e "${GREEN}FIREWALL:${RESET} UFWSTATUS OPEN80 OPEN443 OPENSSH"
    fi

    if has_service apache2 || has_service nginx; then
        echo -e "${GREEN}WEBSERVER:${RESET} WEBSTART WEBSTOP WEBRESTART"
    fi

    if has_cmd nmap || has_cmd msfconsole; then
        echo -e "${GREEN}SECURITY:${RESET}  NMAP METASPLOIT WIRESHARK SQLMAP"
    fi

    echo ""
    echo -e "Type ${BLUE}EASYHELP${RESET} for detailed information"
}

# =====================================================
# SYSTEM COMMANDS
# =====================================================
alias POWEROFF='LOG "POWEROFF executed"; sudo poweroff'
alias REBOOT='LOG "REBOOT executed"; sudo reboot'
alias SHUTDOWN='LOG "SHUTDOWN executed"; sudo shutdown now'

# =====================================================
# PACKAGE MANAGEMENT (APT)
# =====================================================
alias UPDATE='LOG "APT UPDATE executed"; sudo apt update'
alias UPGRADE='LOG "APT UPGRADE executed"; sudo apt upgrade -y'
alias INSTALL='sudo apt install -y'
alias REMOVE='sudo apt remove --purge -y'
alias APTSEARCH='apt search'
alias APTCLEAN='LOG "APT CLEAN executed"; sudo apt autoclean && sudo apt autoremove -y'

# =====================================================
# NETWORK COMMANDS
# =====================================================
alias PING='ping -c 4'
alias IP='ip address show'

# =====================================================
# FIREWALL COMMANDS (UFW)
# =====================================================
alias UFWSTATUS='sudo ufw status verbose'
alias OPEN80='LOG "UFW OPEN80 executed"; sudo ufw allow 80/tcp'
alias OPEN443='LOG "UFW OPEN443 executed"; sudo ufw allow 443/tcp'
alias OPENSSH='LOG "UFW OPENSSH executed"; sudo ufw allow 22/tcp'

# =====================================================
# WEBSERVER HANDLING (Nginx prioritized over Apache2)
# =====================================================
if has_service nginx; then
    alias WEBSTART='LOG "NGINX START"; sudo systemctl start nginx'
    alias WEBSTOP='LOG "NGINX STOP"; sudo systemctl stop nginx'
    alias WEBRESTART='LOG "NGINX RESTART"; sudo systemctl restart nginx'
elif has_service apache2; then
    alias WEBSTART='LOG "APACHE2 START"; sudo systemctl start apache2'
    alias WEBSTOP='LOG "APACHE2 STOP"; sudo systemctl stop apache2'
    alias WEBRESTART='LOG "APACHE2 RESTART"; sudo systemctl restart apache2'
fi

# =====================================================
# SECURITY TOOLS
# =====================================================
alias NMAP='sudo nmap'
alias METASPLOIT='sudo msfconsole'
alias WIRESHARK='sudo wireshark'
alias SQLMAP='sqlmap'

# =====================================================
# HELP COMMAND
# =====================================================
EASYHELP() {
    cat << HELPEOF
${BLUE}1002xEASYCOMMAND v2.2 Hub${RESET}

${GREEN}USAGE:${RESET}
Simply type the commands listed in CAPITAL letters.

${GREEN}SYSTEM MANAGEMENT:${RESET}
  POWEROFF   - Shutdown system immediately
  REBOOT     - Reboot system
  SHUTDOWN   - Shutdown system

${GREEN}PACKAGE MANAGEMENT:${RESET}
  UPDATE     - Update package lists (sudo apt update)
  UPGRADE    - Upgrade installed packages (sudo apt upgrade -y)
  INSTALL    - Install packages (usage: INSTALL package-name)
  REMOVE     - Remove packages (usage: REMOVE package-name)
  APTSEARCH  - Search for packages (usage: APTSEARCH search-term)
  APTCLEAN   - Clean up unused packages

${GREEN}NETWORK:${RESET}
  PING       - Ping host (sends 4 packets)
  IP         - Show IP addresses and interfaces

${GREEN}FIREWALL (UFW):${RESET}
  UFWSTATUS  - Show firewall status
  OPEN80     - Allow HTTP traffic (port 80)
  OPEN443    - Allow HTTPS traffic (port 443)
  OPENSSH    - Allow SSH connections (port 22)

${GREEN}WEBSERVER:${RESET}
  WEBSTART   - Start web server (nginx or apache2)
  WEBSTOP    - Stop web server
  WEBRESTART - Restart web server

${GREEN}SECURITY TOOLS:${RESET}
  NMAP       - Network mapper (usage: NMAP target)
  METASPLOIT - Metasploit console
  WIRESHARK  - Network protocol analyzer
  SQLMAP     - SQL injection testing tool

${GREEN}LOG FILE:${RESET}
  All important actions are logged to: /var/log/1002xEASYCOMMAND.log

${YELLOW}Example:${RESET}
  1002xEASYCOMMAND     - Show available commands
  EASYHELP             - Display this help message
  INSTALL nginx        - Install nginx package
  PING 8.8.8.8         - Ping Google's DNS server

HELPEOF
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

# Define color variables for output (outside of heredoc)
BLUE="\e[34m"
RESET="\e[0m"

echo ""
echo -e "${BLUE}========== Installation Summary ==========${RESET}"
echo "[✓] Installation successful (v2.2)"
echo "[✓] Main file:  $MAIN_FILE"
echo "[✓] Log file:   $LOG_FILE"
echo ""
echo "Please run one of the following:"
echo "  • source /etc/bash.bashrc"
echo "  • Log out and back in"
echo "  • Start a new terminal session"
echo ""
echo "Then type: 1002xEASYCOMMAND"
