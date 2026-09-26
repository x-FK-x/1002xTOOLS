#!/bin/bash
# ============================================================
#  set-language.sh – Language / Locale configuration
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
[ "$(id -u)" -eq 0 ] || error "This script must be run as root.\nUse: sudo ./set-language.sh"

# ----------------------------------------------------------
# DEPENDENCY CHECK
# ----------------------------------------------------------
command -v whiptail &>/dev/null || error "whiptail is required but not installed."

# ----------------------------------------------------------
# AVAILABLE LANGUAGES
# ----------------------------------------------------------
LANGUAGES=(
    "en_US.UTF-8"  "English (US)"
    "en_GB.UTF-8"  "English (UK)"
    "de_DE.UTF-8"  "German"
    "fr_FR.UTF-8"  "French"
    "es_ES.UTF-8"  "Spanish"
    "it_IT.UTF-8"  "Italian"
    "pt_PT.UTF-8"  "Portuguese"
    "pt_BR.UTF-8"  "Portuguese (Brazil)"
    "nl_NL.UTF-8"  "Dutch"
    "pl_PL.UTF-8"  "Polish"
    "ru_RU.UTF-8"  "Russian"
    "tr_TR.UTF-8"  "Turkish"
    "sv_SE.UTF-8"  "Swedish"
    "cs_CZ.UTF-8"  "Czech"
    "el_GR.UTF-8"  "Greek"
    "ja_JP.UTF-8"  "Japanese"
    "zh_CN.UTF-8"  "Chinese (Simplified)"
)

# ----------------------------------------------------------
# STEP 1: Select locale
# ----------------------------------------------------------
LOCALE=$(whiptail --title "Language / Locale" \
    --menu "Select the system language:" 20 60 12 \
    "${LANGUAGES[@]}" \
    3>&1 1>&2 2>&3) || exit 0

# ----------------------------------------------------------
# STEP 2: Confirm
# ----------------------------------------------------------
whiptail --title "Confirm" \
    --yesno "Set system language to:\n\n  $LOCALE\n\nContinue?" \
    12 55 || exit 0

# ----------------------------------------------------------
# STEP 3: Apply
# ----------------------------------------------------------
info "Enabling locale $LOCALE in /etc/locale.gen ..."

if [ -f /etc/locale.gen ]; then
    sed -i "s/^# *${LOCALE} /${LOCALE} /" /etc/locale.gen
    grep -q "^${LOCALE} " /etc/locale.gen || echo "${LOCALE} UTF-8" >> /etc/locale.gen
else
    warn "/etc/locale.gen not found, creating it."
    echo "${LOCALE} UTF-8" > /etc/locale.gen
fi

info "Writing /etc/default/locale ..."
echo "LANG=${LOCALE}" > /etc/default/locale

info "Generating locale (this may take a moment) ..."
locale-gen

info "Applying system-wide default ..."
update-locale "LANG=${LOCALE}"

# ----------------------------------------------------------
# DONE
# ----------------------------------------------------------
whiptail --title "Language Configured" \
    --msgbox "System language has been set to:\n\n  $LOCALE\n\nLog out and back in (or reboot) for it to take full effect." \
    12 55

info "Done. Active language: $LOCALE"
