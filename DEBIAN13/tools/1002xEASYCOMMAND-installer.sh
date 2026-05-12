#!/bin/bash

set -euo pipefail

VERSION="3.2"

MAIN_FILE="/etc/profile.d/1002xEASYCOMMAND.sh"
BASHRC="/etc/bash.bashrc"
LOG_FILE="/var/log/1002xEASYCOMMAND.log"

# =====================================================
# ROOT CHECK
# =====================================================

if [[ $EUID -ne 0 ]]; then
    echo "[!] Run as root (sudo)"
    exit 1
fi

# =====================================================
# LOGGING
# =====================================================

touch "$LOG_FILE"
chmod 640 "$LOG_FILE"

log() {
    echo "$(date '+%F %T') | $1" >> "$LOG_FILE"
}

# =====================================================
# UNINSTALL
# =====================================================

if [[ "${1:-}" == "uninstall" ]]; then
    echo "[*] Removing..."
    rm -f "$MAIN_FILE"
    sed -i '/1002xEASYCOMMAND/d' "$BASHRC"
    rm -f "$LOG_FILE"
    echo "[✓] Removed"
    exit 0
fi

# =====================================================
# RUNTIME FILE
# =====================================================

cat > "$MAIN_FILE" <<'EOF'

# =====================================================
# 1002xEASYCOMMAND SAFE RUNTIME v3.2
# =====================================================

LOGFILE="/var/log/1002xEASYCOMMAND.log"

log() {
    echo "$(date '+%F %T') | $1" >> "$LOGFILE"
}

# =====================================================
# SAFETY CORE
# =====================================================

confirm() {
    read -rp "[CONFIRM] $1 (yes/no): " a
    [[ "$a" == "yes" ]]
}

# =====================================================
# SYSTEM
# =====================================================

POWEROFF() { log "POWEROFF"; poweroff; }
REBOOT() { log "REBOOT"; reboot; }
SHUTDOWN() { log "SHUTDOWN"; shutdown now; }

# =====================================================
# APT
# =====================================================

APT_UPDATE() { log "APT UPDATE"; apt update; }
APT_UPGRADE() { log "APT UPGRADE"; apt upgrade -y; }
APT_INSTALL() { log "APT INSTALL $*"; apt install -y "$@"; }
APT_REMOVE() { log "APT REMOVE $*"; apt remove -y "$@"; }

# =====================================================
# NETWORK
# =====================================================

PING() { log "PING $1"; ping -c 4 "$1"; }
IP() { ip a; }

# =====================================================
# FIREWALL
# =====================================================

OPEN80() { log "OPEN80"; ufw allow 80/tcp; }
BLOCK80() { log "BLOCK80"; ufw deny 80/tcp; }

OPEN443() { log "OPEN443"; ufw allow 443/tcp; }
BLOCK443() { log "BLOCK443"; ufw deny 443/tcp; }

OPENSSH() { log "OPENSSH"; ufw allow 22/tcp; }
BLOCKSSH() { log "BLOCKSSH"; ufw deny 22/tcp; }

FW_STATUS() { ufw status verbose; }

# =====================================================
# WEBSERVER
# =====================================================

WEB_START() {
    if systemctl list-unit-files | grep -q nginx; then
        log "WEB START nginx"
        systemctl start nginx
    elif systemctl list-unit-files | grep -q apache2; then
        log "WEB START apache2"
        systemctl start apache2
    fi
}

WEB_STOP() {
    if systemctl list-unit-files | grep -q nginx; then
        log "WEB STOP nginx"
        systemctl stop nginx
    elif systemctl list-unit-files | grep -q apache2; then
        systemctl stop apache2
    fi
}

WEB_RESTART() {
    WEB_STOP
    WEB_START
}

# =====================================================
# DISK
# =====================================================

DISK_LIST() { lsblk -o NAME,SIZE,TYPE,MOUNTPOINT; }
DISK_USAGE() { df -h; }

# =====================================================
# EASYHELP (HARDCODED - FIXED STABLE VERSION)
# =====================================================

EASYHELP() {

clear

echo "1002xEASYCOMMAND v3.2"
echo "================================================="

echo ""
echo "SYSTEM:"
echo "  POWEROFF    Shutdown system immediately"
echo "  REBOOT      Reboot system"
echo "  SHUTDOWN    Shutdown system immediately"

echo ""
echo "PACKAGE MANAGEMENT:"
echo "  UPDATE      sudo apt update"
echo "  UPGRADE     sudo apt upgrade -y"
echo "  FULLUPGRADE sudo apt full-upgrade -y"
echo "  DISTUPGRADE sudo apt dist-upgrade -y"
echo "  INSTALL     Install package"
echo "  REMOVE      Remove package"
echo "  PURGE       Remove package incl. config"
echo "  REINSTALL   Reinstall package"
echo "  AUTOREMOVE  Remove unused dependencies"
echo "  AUTOCLEAN   Clean old cache"
echo "  CLEAN       Full cache cleanup"
echo "  APTSEARCH   Search packages"
echo "  APTSHOW     Show package info"
echo "  APTPOLICY   Show package policy"
echo "  APTINSTALLED Installed packages"
echo "  FIXBROKEN   Repair packages"
echo "  APTCHECK    Check system"
echo "  APTFAST     Fast update/upgrade"
echo "  APTFIX      Repair system"
echo "  APTMAINTAIN Full maintenance"

echo ""
echo "NETWORK:"
echo "  PING host   Ping host"
echo "  IP          Show IP addresses"

echo ""
echo "FIREWALL:"
echo "  OPEN80      Open HTTP"
echo "  BLOCK80     Close HTTP"
echo "  OPEN443     Open HTTPS"
echo "  BLOCK443    Close HTTPS"
echo "  OPENSSH     Open SSH"
echo "  BLOCKSSH    Close SSH"
echo "  FW_STATUS   Show firewall status"

echo ""
echo "WEBSERVER:"
echo "  WEB_START   Start server"
echo "  WEB_STOP    Stop server"
echo "  WEB_RESTART Restart server"

echo ""
echo "LOG FILE:"
echo "  /var/log/1002xEASYCOMMAND.log"

echo ""
echo "EXAMPLES:"
echo "  INSTALL nginx"
echo "  REMOVE apache2"
echo "  PING 8.8.8.8"
echo "  APTSEARCH docker"
echo "  APTSHOW bash"

}
EOF

chmod 644 "$MAIN_FILE"

# =====================================================
# BASHRC INJECTION
# =====================================================

if ! grep -q "1002xEASYCOMMAND" "$BASHRC"; then
    echo "" >> "$BASHRC"
    echo "# 1002xEASYCOMMAND v3.2" >> "$BASHRC"
    echo "source $MAIN_FILE" >> "$BASHRC"
fi

source "$MAIN_FILE"

echo ""
echo "====================================="
echo "  1002xEASYCOMMAND INSTALLED"
echo "  VERSION: $VERSION (HARD MODE)"
echo "====================================="
echo ""
echo "Run: EASYHELP"
