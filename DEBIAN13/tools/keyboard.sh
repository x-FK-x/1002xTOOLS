#!/bin/bash
# ============================================================
#  set-keyboard.sh – Keyboard layout configuration
#  Standalone tool extracted from the MODOS/DODOS installer.
#  Run directly on the target system (or inside a chroot).
# ============================================================

set -euo pipefail

# ----------------------------------------------------------
# COLORS
# ----------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error() {
    echo -e "${RED}[ERROR]${NC} $1"
    command -v whiptail &>/dev/null && whiptail --title "Error" --msgbox "$1" 8 60
    exit 1
}

# ----------------------------------------------------------
# ROOT CHECK
# ----------------------------------------------------------
[ "$(id -u)" -eq 0 ] || error "This script must be run as root.\nUse: sudo ./set-keyboard.sh"

# ----------------------------------------------------------
# DEPENDENCY CHECK
# ----------------------------------------------------------
command -v whiptail &>/dev/null || error "whiptail is required but not installed."

# ----------------------------------------------------------
# AVAILABLE LAYOUTS
# ----------------------------------------------------------
LAYOUTS=(
    "us" "English (US)"
    "gb" "English (UK)"
    "de" "German"
    "ch" "Swiss"
    "fr" "French"
    "es" "Spanish"
    "it" "Italian"
    "pt" "Portuguese"
    "br" "Portuguese (Brazil)"
    "nl" "Dutch"
    "pl" "Polish"
    "ru" "Russian"
    "tr" "Turkish"
    "se" "Swedish"
    "cz" "Czech"
    "gr" "Greek"
    "jp" "Japanese"
)

# ----------------------------------------------------------
# STEP 1: Select layout
# ----------------------------------------------------------
KEYLAYOUT=$(whiptail --title "Keyboard Layout" \
    --menu "Select the keyboard layout:" 20 60 12 \
    "${LAYOUTS[@]}" \
    3>&1 1>&2 2>&3) || exit 0

# ----------------------------------------------------------
# STEP 2: Confirm
# ----------------------------------------------------------
whiptail --title "Confirm" \
    --yesno "Set keyboard layout to:\n\n  $KEYLAYOUT\n\nContinue?" \
    12 55 || exit 0

# ----------------------------------------------------------
# STEP 3: Apply
# ----------------------------------------------------------
info "Writing /etc/default/keyboard ..."

if [ -f /etc/default/keyboard ]; then
    sed -i "s/^XKBLAYOUT=.*/XKBLAYOUT=\"${KEYLAYOUT}\"/" /etc/default/keyboard
else
    warn "/etc/default/keyboard not found, creating it."
    cat > /etc/default/keyboard <<EOF
XKBMODEL="pc105"
XKBLAYOUT="${KEYLAYOUT}"
XKBVARIANT=""
XKBOPTIONS=""
EOF
fi

info "Applying console keymap ..."
setupcon 2>/dev/null || warn "setupcon failed (no active console? this is fine inside a chroot)."

if command -v dpkg-reconfigure &>/dev/null; then
    info "Refreshing keyboard-configuration package state ..."
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive keyboard-configuration 2>/dev/null || true
fi

# ----------------------------------------------------------
# DONE
# ----------------------------------------------------------
whiptail --title "Keyboard Configured" \
    --msgbox "Keyboard layout has been set to:\n\n  $KEYLAYOUT\n\nLog out and back in (or reboot) for it to take full effect in your desktop session." \
    12 55

info "Done. Active layout: $KEYLAYOUT"
