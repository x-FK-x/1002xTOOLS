#!/bin/bash
# ============================================================
#  debian-sources.sh — Debian APT Sources Configuration
#  Supports: Debian 13 (trixie/stable) and Testing
#  Run with: sudo bash debian-sources.sh
# ============================================================

set -euo pipefail

SOURCES_FILE="/etc/apt/sources.list"
BACKUP_DIR="/etc/apt"
BACKUP_PREFIX="sources.list.bak."
TITLE="Debian APT Sources Configuration"
W=70  # whiptail width
H=20  # whiptail default height

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    whiptail --title "$TITLE" --msgbox "Please run as root or with sudo." 8 50
    exit 1
fi

# --- whiptail check ---
if ! command -v whiptail &>/dev/null; then
    echo "whiptail not found. Install it with: apt install whiptail"
    exit 1
fi

# ============================================================
#  Mirror definitions  (tag label hostname)
# ============================================================

REGIONS=(
    "1" "Official / CDN"
    "2" "Europe"
    "3" "North America"
    "4" "Asia"
    "5" "Oceania"
    "6" "South America"
    "7" "Africa"
)

declare -a R0=( "deb.debian.org" "Official Anycast CDN" )

declare -a R1=(
    "ftp.de.debian.org"         "Germany"
    "ftp.at.debian.org"         "Austria"
    "ftp.ch.debian.org"         "Switzerland"
    "ftp.nl.debian.org"         "Netherlands"
    "ftp.fr.debian.org"         "France"
    "ftp.uk.debian.org"         "United Kingdom"
    "ftp.pl.debian.org"         "Poland"
    "ftp.se.debian.org"         "Sweden"
    "mirror.selfnet.de"         "Germany - Selfnet"
    "debian.anexia.at"          "Austria - Anexia"
)

declare -a R2=(
    "ftp.us.debian.org"             "USA - Official"
    "mirror.math.ucdavis.edu"       "USA - UC Davis"
    "mirrors.ocf.berkeley.edu"      "USA - UC Berkeley"
    "debian.mirror.constant.com"    "USA - Constant"
    "ftp.ca.debian.org"             "Canada - Official"
    "mirror.csclub.uwaterloo.ca"    "Canada - UWaterloo"
)

declare -a R3=(
    "ftp.jp.debian.org"             "Japan"
    "ftp.cn.debian.org"             "China"
    "ftp.kr.debian.org"             "South Korea"
    "ftp.tw.debian.org"             "Taiwan"
    "ftp.in.debian.org"             "India"
    "ftp.id.debian.org"             "Indonesia"
    "mirror.nus.edu.sg"             "Singapore - NUS"
    "mirrors.tuna.tsinghua.edu.cn"  "China - Tsinghua"
)

declare -a R4=(
    "ftp.au.debian.org"                     "Australia - Official"
    "mirror.aarnet.edu.au"                  "Australia - AARNet"
    "debian.mirror.digitalpacific.com.au"   "Australia - Digital Pacific"
    "ftp.nz.debian.org"                     "New Zealand - Official"
    "mirror.fsmg.org.nz"                    "New Zealand - FSMG"
)

declare -a R5=(
    "ftp.br.debian.org"     "Brazil - Official"
    "ftp.ar.debian.org"     "Argentina"
    "ftp.cl.debian.org"     "Chile"
    "ftp.co.debian.org"     "Colombia"
    "debian.c3sl.ufpr.br"   "Brazil - UFPR"
)

declare -a R6=(
    "ftp.za.debian.org"     "South Africa - Official"
    "mirror.ac.za"          "South Africa - TENET"
    "debian.mirror.ac.ke"   "Kenya"
    "ftp.eg.debian.org"     "Egypt"
    "mirror.marwan.ma"      "Morocco - MARWAN"
)

# Return nameref to region array by index (1-based)
get_region_array() {
    case "$1" in
        1) echo "R0" ;;
        2) echo "R1" ;;
        3) echo "R2" ;;
        4) echo "R3" ;;
        5) echo "R4" ;;
        6) echo "R5" ;;
        7) echo "R6" ;;
    esac
}

# ============================================================
#  Main menu
# ============================================================
main_menu() {
    while true; do
        local choice
        choice=$(whiptail --title "$TITLE" \
            --menu "Main Menu" $H $W 5 \
            "1" "Configure APT Sources" \
            "2" "Restore from Backup" \
            "3" "Manage Backups" \
            "4" "Show Current sources.list" \
            "5" "Quit" \
            3>&1 1>&2 2>&3) || exit 0

        case "$choice" in
            1) configure_sources ;;
            2) restore_backup    ;;
            3) manage_backups    ;;
            4) show_current      ;;
            5) exit 0            ;;
        esac
    done
}

# ============================================================
#  Show current sources.list
# ============================================================
show_current() {
    if [[ ! -f "$SOURCES_FILE" ]]; then
        whiptail --title "$TITLE" --msgbox "${SOURCES_FILE} does not exist." 8 $W
        return
    fi
    local content
    content=$(cat "$SOURCES_FILE")
    whiptail --title "Current: ${SOURCES_FILE}" \
        --scrolltext --msgbox "$content" 24 $W
}

# ============================================================
#  Restore backup
# ============================================================
restore_backup() {
    local -a BACKUPS
    mapfile -t BACKUPS < <(ls -t "${BACKUP_DIR}/${BACKUP_PREFIX}"* 2>/dev/null || true)

    if [[ ${#BACKUPS[@]} -eq 0 ]]; then
        whiptail --title "$TITLE" --msgbox "No backups found in ${BACKUP_DIR}." 8 $W
        return
    fi

    # Build menu items: tag = index, item = filename + size
    local -a MENU_ITEMS=()
    local i=1
    for f in "${BACKUPS[@]}"; do
        local size
        size=$(du -h "$f" | cut -f1)
        MENU_ITEMS+=( "$i" "$(basename "$f")  [${size}]" )
        (( i++ ))
    done

    local choice
    choice=$(whiptail --title "$TITLE" \
        --menu "Select backup to restore (newest first):" $H $W "${#BACKUPS[@]}" \
        "${MENU_ITEMS[@]}" \
        3>&1 1>&2 2>&3) || return

    local selected="${BACKUPS[$((choice-1))]}"
    local preview
    preview=$(cat "$selected")

    whiptail --title "Preview: $(basename "$selected")" \
        --scrolltext --msgbox "$preview" 24 $W

    if whiptail --title "$TITLE" \
        --yesno "Restore $(basename "$selected") to ${SOURCES_FILE}?" 8 $W; then

        # Back up current before overwriting
        if [[ -f "$SOURCES_FILE" ]]; then
            local now_bak="${BACKUP_DIR}/${BACKUP_PREFIX}$(date +%Y%m%d_%H%M%S)"
            cp "$SOURCES_FILE" "$now_bak"
        fi
        cp "$selected" "$SOURCES_FILE"

        if whiptail --title "$TITLE" \
            --yesno "Restored successfully.\n\nRun apt update now?" 9 $W; then
            clear
            apt update
            echo ""
            read -rp "  Press Enter to return..." _
        else
            whiptail --title "$TITLE" --msgbox "Restored: $(basename "$selected")" 8 $W
        fi
    fi
}

# ============================================================
#  Manage backups
# ============================================================
manage_backups() {
    while true; do
        local -a BACKUPS
        mapfile -t BACKUPS < <(ls -t "${BACKUP_DIR}/${BACKUP_PREFIX}"* 2>/dev/null || true)

        if [[ ${#BACKUPS[@]} -eq 0 ]]; then
            whiptail --title "$TITLE" --msgbox "No backups found." 8 $W
            return
        fi

        local -a MENU_ITEMS=()
        local i=1
        for f in "${BACKUPS[@]}"; do
            local size
            size=$(du -h "$f" | cut -f1)
            MENU_ITEMS+=( "$i" "$(basename "$f")  [${size}]" )
            (( i++ ))
        done
        MENU_ITEMS+=( "A" "Delete ALL backups" )

        local choice
        choice=$(whiptail --title "$TITLE" \
            --menu "Manage Backups — select entry to delete:" $H $W "$(( ${#BACKUPS[@]} + 1 ))" \
            "${MENU_ITEMS[@]}" \
            3>&1 1>&2 2>&3) || return

        if [[ "${choice^^}" == "A" ]]; then
            if whiptail --title "$TITLE" \
                --yesno "Delete ALL ${#BACKUPS[@]} backups?" 8 $W; then
                for f in "${BACKUPS[@]}"; do rm -f "$f"; done
                whiptail --title "$TITLE" --msgbox "All backups deleted." 8 $W
            fi
        elif [[ "$choice" =~ ^[0-9]+$ ]]; then
            local target="${BACKUPS[$((choice-1))]}"
            if whiptail --title "$TITLE" \
                --yesno "Delete $(basename "$target")?" 8 $W; then
                rm -f "$target"
                whiptail --title "$TITLE" --msgbox "Deleted: $(basename "$target")" 8 $W
            fi
        fi
    done
}

# ============================================================
#  Configure — Step 1: Release
# ============================================================
choose_release() {
    local choice
    choice=$(whiptail --title "$TITLE" \
        --menu "Step 1 / 4 — Select Release" $H $W 2 \
        "trixie"  "Debian 13 Trixie  (stable — recommended)" \
        "testing" "Testing            (rolling, latest packages)" \
        3>&1 1>&2 2>&3) || return 1

    RELEASE="$choice"
    if [[ "$RELEASE" == "trixie" ]]; then
        RELEASE_LABEL="Debian 13 Trixie (stable)"
    else
        RELEASE_LABEL="Testing (rolling)"
    fi
    return 0
}

# ============================================================
#  Step 2: Region → Mirror
# ============================================================
choose_mirror() {
    local reg_choice
    reg_choice=$(whiptail --title "$TITLE" \
        --menu "Step 2 / 4 — Select Region" $H $W 7 \
        "${REGIONS[@]}" \
        3>&1 1>&2 2>&3) || return 1

    # Get the array name for the chosen region
    local arr_name
    arr_name=$(get_region_array "$reg_choice")

    # Build mirror menu from that array (pairs: hostname label)
    local -n arr_ref="$arr_name"
    local -a MIR_ITEMS=()
    local i=0
    while (( i < ${#arr_ref[@]} )); do
        MIR_ITEMS+=( "${arr_ref[$i]}" "${arr_ref[$((i+1))]}" )
        (( i += 2 ))
    done

    local region_label="${REGIONS[$((reg_choice*2-1))]}"

    local mir_choice
    mir_choice=$(whiptail --title "$TITLE" \
        --menu "Step 2 / 4 — Select Mirror: ${region_label}" $H $W "$(( ${#MIR_ITEMS[@]} / 2 ))" \
        "${MIR_ITEMS[@]}" \
        3>&1 1>&2 2>&3) || return 1

    MIRROR="$mir_choice"
    # Find label for the chosen mirror
    i=0
    while (( i < ${#arr_ref[@]} )); do
        if [[ "${arr_ref[$i]}" == "$mir_choice" ]]; then
            MIRROR_LABEL="${arr_ref[$((i+1))]}"
            break
        fi
        (( i += 2 ))
    done
    return 0
}

# ============================================================
#  Step 3: Components
# ============================================================
choose_components() {
    local choice
    choice=$(whiptail --title "$TITLE" \
        --menu "Step 3 / 4 — Select Components" $H $W 4 \
        "main"                                    "Free software only" \
        "main contrib"                            "Free + Contrib" \
        "main contrib non-free"                   "Free + Contrib + Non-Free" \
        "main contrib non-free non-free-firmware" "Full (recommended)" \
        3>&1 1>&2 2>&3) || return 1

    COMPONENTS="$choice"
    return 0
}

# ============================================================
#  Step 4: Extra repos  (checklist)
# ============================================================
choose_extras() {
    local bp_item=""
    if [[ "$RELEASE" == "trixie" ]]; then
        bp_item='"backports" "Include Backports" OFF'
    fi

    local result
    result=$(eval whiptail --title "$TITLE" \
        --checklist '"Step 4 / 4 — Additional Repositories\n(Space to toggle, Enter to confirm)"' \
        $H $W 3 \
        '"security" "Include Security Updates" ON' \
        '"updates"  "Include Updates Repo"     ON' \
        $bp_item \
        3>&1 1>&2 2>&3) || return 1

    USE_SECURITY="n"; USE_UPDATES="n"; USE_BACKPORTS="n"
    [[ "$result" == *"security"* ]] && USE_SECURITY="y"
    [[ "$result" == *"updates"*  ]] && USE_UPDATES="y"
    [[ "$result" == *"backports"* ]] && USE_BACKPORTS="y"
    return 0
}

# ============================================================
#  Build sources.list
# ============================================================
build_sources() {
    local proto="http"
    SOURCES_CONTENT=""
    SOURCES_CONTENT+="# Debian ${RELEASE_LABEL}\n"
    SOURCES_CONTENT+="# Generated by debian-sources.sh on $(date)\n"
    SOURCES_CONTENT+="# Mirror: ${MIRROR_LABEL}\n\n"
    SOURCES_CONTENT+="# Main repository\n"
    SOURCES_CONTENT+="deb ${proto}://${MIRROR}/debian ${RELEASE} ${COMPONENTS}\n"
    SOURCES_CONTENT+="deb-src ${proto}://${MIRROR}/debian ${RELEASE} ${COMPONENTS}\n"

    if [[ "$USE_SECURITY" == "y" ]]; then
        if [[ "$RELEASE" == "trixie" ]]; then
            SOURCES_CONTENT+="\n# Security\n"
            SOURCES_CONTENT+="deb ${proto}://security.debian.org/debian-security ${RELEASE}-security ${COMPONENTS}\n"
            SOURCES_CONTENT+="deb-src ${proto}://security.debian.org/debian-security ${RELEASE}-security ${COMPONENTS}\n"
        else
            SOURCES_CONTENT+="\n# Security (testing)\n"
            SOURCES_CONTENT+="deb ${proto}://security.debian.org/debian-security testing-security ${COMPONENTS}\n"
            SOURCES_CONTENT+="deb-src ${proto}://security.debian.org/debian-security testing-security ${COMPONENTS}\n"
        fi
    fi

    if [[ "$USE_UPDATES" == "y" ]]; then
        SOURCES_CONTENT+="\n# Updates\n"
        SOURCES_CONTENT+="deb ${proto}://${MIRROR}/debian ${RELEASE}-updates ${COMPONENTS}\n"
        SOURCES_CONTENT+="deb-src ${proto}://${MIRROR}/debian ${RELEASE}-updates ${COMPONENTS}\n"
    fi

    if [[ "$USE_BACKPORTS" == "y" ]]; then
        SOURCES_CONTENT+="\n# Backports\n"
        SOURCES_CONTENT+="deb ${proto}://${MIRROR}/debian ${RELEASE}-backports ${COMPONENTS}\n"
        SOURCES_CONTENT+="deb-src ${proto}://${MIRROR}/debian ${RELEASE}-backports ${COMPONENTS}\n"
    fi
}

# ============================================================
#  Preview + Apply
# ============================================================
show_preview_and_apply() {
    # --- Settings summary ---
    local sec_label="No"
    local upd_label="No"
    local bp_label="No"
    [[ "$USE_SECURITY"  == "y" ]] && sec_label="Yes"
    [[ "$USE_UPDATES"   == "y" ]] && upd_label="Yes"
    [[ "$USE_BACKPORTS" == "y" ]] && bp_label="Yes"

    local summary
    summary="Summary of selected settings:

  Release    :  ${RELEASE_LABEL}
  Mirror     :  ${MIRROR}
               (${MIRROR_LABEL})
  Components :  ${COMPONENTS}

  Security   :  ${sec_label}
  Updates    :  ${upd_label}
  Backports  :  ${bp_label}

─────────────────────────────────────────────────
  Target file:  ${SOURCES_FILE}"

    whiptail --title "Settings Overview" \
        --msgbox "$summary" 20 $W

    # --- File preview ---
    whiptail --title "Preview: ${SOURCES_FILE}" \
        --scrolltext --msgbox "$(echo -e "$SOURCES_CONTENT")" 24 $W

    # --- Confirm ---
    if whiptail --title "$TITLE" \
        --yesno "Apply these changes to ${SOURCES_FILE}?" 8 $W; then

        if [[ -f "$SOURCES_FILE" ]]; then
            local bak="${BACKUP_DIR}/${BACKUP_PREFIX}$(date +%Y%m%d_%H%M%S)"
            cp "$SOURCES_FILE" "$bak"
        fi
        echo -e "$SOURCES_CONTENT" > "$SOURCES_FILE"

        if whiptail --title "$TITLE" \
            --yesno "sources.list written successfully.\n\nRun apt update now?" 9 $W; then
            clear
            apt update
            echo ""
            read -rp "  Press Enter to return..." _
        else
            whiptail --title "$TITLE" \
                --msgbox "Done! Sources configured successfully." 8 $W
        fi
    else
        whiptail --title "$TITLE" --msgbox "Cancelled. No changes made." 8 $W
    fi
}

# ============================================================
#  Configure sources — full wizard
# ============================================================
configure_sources() {
    RELEASE=""
    RELEASE_LABEL=""
    MIRROR=""
    MIRROR_LABEL=""
    COMPONENTS=""
    USE_SECURITY="y"
    USE_UPDATES="y"
    USE_BACKPORTS="n"
    SOURCES_CONTENT=""

    choose_release    || return
    choose_mirror     || return
    choose_components || return
    choose_extras     || return
    build_sources
    show_preview_and_apply
}

# ============================================================
#  Entry point
# ============================================================
main_menu#!/bin/bash
# ============================================================
#  debian-sources.sh — Debian APT Sources Configuration
#  Supports: Debian 13 (trixie/stable) and Testing
#  Run with: sudo bash debian-sources.sh
# ============================================================

set -euo pipefail

SOURCES_FILE="/etc/apt/sources.list"
BACKUP_DIR="/etc/apt"
BACKUP_PREFIX="sources.list.bak."
TITLE="Debian APT Sources Configuration"
W=70  # whiptail width
H=20  # whiptail default height

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    whiptail --title "$TITLE" --msgbox "Please run as root or with sudo." 8 50
    exit 1
fi

# --- whiptail check ---
if ! command -v whiptail &>/dev/null; then
    echo "whiptail not found. Install it with: apt install whiptail"
    exit 1
fi

# ============================================================
#  Mirror definitions  (tag label hostname)
# ============================================================

REGIONS=(
    "1" "Official / CDN"
    "2" "Europe"
    "3" "North America"
    "4" "Asia"
    "5" "Oceania"
    "6" "South America"
    "7" "Africa"
)

declare -a R0=( "deb.debian.org" "Official Anycast CDN" )

declare -a R1=(
    "ftp.de.debian.org"         "Germany"
    "ftp.at.debian.org"         "Austria"
    "ftp.ch.debian.org"         "Switzerland"
    "ftp.nl.debian.org"         "Netherlands"
    "ftp.fr.debian.org"         "France"
    "ftp.uk.debian.org"         "United Kingdom"
    "ftp.pl.debian.org"         "Poland"
    "ftp.se.debian.org"         "Sweden"
    "mirror.selfnet.de"         "Germany - Selfnet"
    "debian.anexia.at"          "Austria - Anexia"
)

declare -a R2=(
    "ftp.us.debian.org"             "USA - Official"
    "mirror.math.ucdavis.edu"       "USA - UC Davis"
    "mirrors.ocf.berkeley.edu"      "USA - UC Berkeley"
    "debian.mirror.constant.com"    "USA - Constant"
    "ftp.ca.debian.org"             "Canada - Official"
    "mirror.csclub.uwaterloo.ca"    "Canada - UWaterloo"
)

declare -a R3=(
    "ftp.jp.debian.org"             "Japan"
    "ftp.cn.debian.org"             "China"
    "ftp.kr.debian.org"             "South Korea"
    "ftp.tw.debian.org"             "Taiwan"
    "ftp.in.debian.org"             "India"
    "ftp.id.debian.org"             "Indonesia"
    "mirror.nus.edu.sg"             "Singapore - NUS"
    "mirrors.tuna.tsinghua.edu.cn"  "China - Tsinghua"
)

declare -a R4=(
    "ftp.au.debian.org"                     "Australia - Official"
    "mirror.aarnet.edu.au"                  "Australia - AARNet"
    "debian.mirror.digitalpacific.com.au"   "Australia - Digital Pacific"
    "ftp.nz.debian.org"                     "New Zealand - Official"
    "mirror.fsmg.org.nz"                    "New Zealand - FSMG"
)

declare -a R5=(
    "ftp.br.debian.org"     "Brazil - Official"
    "ftp.ar.debian.org"     "Argentina"
    "ftp.cl.debian.org"     "Chile"
    "ftp.co.debian.org"     "Colombia"
    "debian.c3sl.ufpr.br"   "Brazil - UFPR"
)

declare -a R6=(
    "ftp.za.debian.org"     "South Africa - Official"
    "mirror.ac.za"          "South Africa - TENET"
    "debian.mirror.ac.ke"   "Kenya"
    "ftp.eg.debian.org"     "Egypt"
    "mirror.marwan.ma"      "Morocco - MARWAN"
)

# Return nameref to region array by index (1-based)
get_region_array() {
    case "$1" in
        1) echo "R0" ;;
        2) echo "R1" ;;
        3) echo "R2" ;;
        4) echo "R3" ;;
        5) echo "R4" ;;
        6) echo "R5" ;;
        7) echo "R6" ;;
    esac
}

# ============================================================
#  Main menu
# ============================================================
main_menu() {
    while true; do
        local choice
        choice=$(whiptail --title "$TITLE" \
            --menu "Main Menu" $H $W 5 \
            "1" "Configure APT Sources" \
            "2" "Restore from Backup" \
            "3" "Manage Backups" \
            "4" "Show Current sources.list" \
            "5" "Quit" \
            3>&1 1>&2 2>&3) || exit 0

        case "$choice" in
            1) configure_sources ;;
            2) restore_backup    ;;
            3) manage_backups    ;;
            4) show_current      ;;
            5) exit 0            ;;
        esac
    done
}

# ============================================================
#  Show current sources.list
# ============================================================
show_current() {
    if [[ ! -f "$SOURCES_FILE" ]]; then
        whiptail --title "$TITLE" --msgbox "${SOURCES_FILE} does not exist." 8 $W
        return
    fi
    local content
    content=$(cat "$SOURCES_FILE")
    whiptail --title "Current: ${SOURCES_FILE}" \
        --scrolltext --msgbox "$content" 24 $W
}

# ============================================================
#  Restore backup
# ============================================================
restore_backup() {
    local -a BACKUPS
    mapfile -t BACKUPS < <(ls -t "${BACKUP_DIR}/${BACKUP_PREFIX}"* 2>/dev/null || true)

    if [[ ${#BACKUPS[@]} -eq 0 ]]; then
        whiptail --title "$TITLE" --msgbox "No backups found in ${BACKUP_DIR}." 8 $W
        return
    fi

    # Build menu items: tag = index, item = filename + size
    local -a MENU_ITEMS=()
    local i=1
    for f in "${BACKUPS[@]}"; do
        local size
        size=$(du -h "$f" | cut -f1)
        MENU_ITEMS+=( "$i" "$(basename "$f")  [${size}]" )
        (( i++ ))
    done

    local choice
    choice=$(whiptail --title "$TITLE" \
        --menu "Select backup to restore (newest first):" $H $W "${#BACKUPS[@]}" \
        "${MENU_ITEMS[@]}" \
        3>&1 1>&2 2>&3) || return

    local selected="${BACKUPS[$((choice-1))]}"
    local preview
    preview=$(cat "$selected")

    whiptail --title "Preview: $(basename "$selected")" \
        --scrolltext --msgbox "$preview" 24 $W

    if whiptail --title "$TITLE" \
        --yesno "Restore $(basename "$selected") to ${SOURCES_FILE}?" 8 $W; then

        # Back up current before overwriting
        if [[ -f "$SOURCES_FILE" ]]; then
            local now_bak="${BACKUP_DIR}/${BACKUP_PREFIX}$(date +%Y%m%d_%H%M%S)"
            cp "$SOURCES_FILE" "$now_bak"
        fi
        cp "$selected" "$SOURCES_FILE"

        if whiptail --title "$TITLE" \
            --yesno "Restored successfully.\n\nRun apt update now?" 9 $W; then
            clear
            apt update
            echo ""
            read -rp "  Press Enter to return..." _
        else
            whiptail --title "$TITLE" --msgbox "Restored: $(basename "$selected")" 8 $W
        fi
    fi
}

# ============================================================
#  Manage backups
# ============================================================
manage_backups() {
    while true; do
        local -a BACKUPS
        mapfile -t BACKUPS < <(ls -t "${BACKUP_DIR}/${BACKUP_PREFIX}"* 2>/dev/null || true)

        if [[ ${#BACKUPS[@]} -eq 0 ]]; then
            whiptail --title "$TITLE" --msgbox "No backups found." 8 $W
            return
        fi

        local -a MENU_ITEMS=()
        local i=1
        for f in "${BACKUPS[@]}"; do
            local size
            size=$(du -h "$f" | cut -f1)
            MENU_ITEMS+=( "$i" "$(basename "$f")  [${size}]" )
            (( i++ ))
        done
        MENU_ITEMS+=( "A" "Delete ALL backups" )

        local choice
        choice=$(whiptail --title "$TITLE" \
            --menu "Manage Backups — select entry to delete:" $H $W "$(( ${#BACKUPS[@]} + 1 ))" \
            "${MENU_ITEMS[@]}" \
            3>&1 1>&2 2>&3) || return

        if [[ "${choice^^}" == "A" ]]; then
            if whiptail --title "$TITLE" \
                --yesno "Delete ALL ${#BACKUPS[@]} backups?" 8 $W; then
                for f in "${BACKUPS[@]}"; do rm -f "$f"; done
                whiptail --title "$TITLE" --msgbox "All backups deleted." 8 $W
            fi
        elif [[ "$choice" =~ ^[0-9]+$ ]]; then
            local target="${BACKUPS[$((choice-1))]}"
            if whiptail --title "$TITLE" \
                --yesno "Delete $(basename "$target")?" 8 $W; then
                rm -f "$target"
                whiptail --title "$TITLE" --msgbox "Deleted: $(basename "$target")" 8 $W
            fi
        fi
    done
}

# ============================================================
#  Configure — Step 1: Release
# ============================================================
choose_release() {
    local choice
    choice=$(whiptail --title "$TITLE" \
        --menu "Step 1 / 4 — Select Release" $H $W 2 \
        "trixie"  "Debian 13 Trixie  (stable — recommended)" \
        "testing" "Testing            (rolling, latest packages)" \
        3>&1 1>&2 2>&3) || return 1

    RELEASE="$choice"
    if [[ "$RELEASE" == "trixie" ]]; then
        RELEASE_LABEL="Debian 13 Trixie (stable)"
    else
        RELEASE_LABEL="Testing (rolling)"
    fi
    return 0
}

# ============================================================
#  Step 2: Region → Mirror
# ============================================================
choose_mirror() {
    local reg_choice
    reg_choice=$(whiptail --title "$TITLE" \
        --menu "Step 2 / 4 — Select Region" $H $W 7 \
        "${REGIONS[@]}" \
        3>&1 1>&2 2>&3) || return 1

    # Get the array name for the chosen region
    local arr_name
    arr_name=$(get_region_array "$reg_choice")

    # Build mirror menu from that array (pairs: hostname label)
    local -n arr_ref="$arr_name"
    local -a MIR_ITEMS=()
    local i=0
    while (( i < ${#arr_ref[@]} )); do
        MIR_ITEMS+=( "${arr_ref[$i]}" "${arr_ref[$((i+1))]}" )
        (( i += 2 ))
    done

    local region_label="${REGIONS[$((reg_choice*2-1))]}"

    local mir_choice
    mir_choice=$(whiptail --title "$TITLE" \
        --menu "Step 2 / 4 — Select Mirror: ${region_label}" $H $W "$(( ${#MIR_ITEMS[@]} / 2 ))" \
        "${MIR_ITEMS[@]}" \
        3>&1 1>&2 2>&3) || return 1

    MIRROR="$mir_choice"
    # Find label for the chosen mirror
    i=0
    while (( i < ${#arr_ref[@]} )); do
        if [[ "${arr_ref[$i]}" == "$mir_choice" ]]; then
            MIRROR_LABEL="${arr_ref[$((i+1))]}"
            break
        fi
        (( i += 2 ))
    done
    return 0
}

# ============================================================
#  Step 3: Components
# ============================================================
choose_components() {
    local choice
    choice=$(whiptail --title "$TITLE" \
        --menu "Step 3 / 4 — Select Components" $H $W 4 \
        "main"                                    "Free software only" \
        "main contrib"                            "Free + Contrib" \
        "main contrib non-free"                   "Free + Contrib + Non-Free" \
        "main contrib non-free non-free-firmware" "Full (recommended)" \
        3>&1 1>&2 2>&3) || return 1

    COMPONENTS="$choice"
    return 0
}

# ============================================================
#  Step 4: Extra repos  (checklist)
# ============================================================
choose_extras() {
    local bp_item=""
    if [[ "$RELEASE" == "trixie" ]]; then
        bp_item='"backports" "Include Backports" OFF'
    fi

    local result
    result=$(eval whiptail --title "$TITLE" \
        --checklist '"Step 4 / 4 — Additional Repositories\n(Space to toggle, Enter to confirm)"' \
        $H $W 3 \
        '"security" "Include Security Updates" ON' \
        '"updates"  "Include Updates Repo"     ON' \
        $bp_item \
        3>&1 1>&2 2>&3) || return 1

    USE_SECURITY="n"; USE_UPDATES="n"; USE_BACKPORTS="n"
    [[ "$result" == *"security"* ]] && USE_SECURITY="y"
    [[ "$result" == *"updates"*  ]] && USE_UPDATES="y"
    [[ "$result" == *"backports"* ]] && USE_BACKPORTS="y"
    return 0
}

# ============================================================
#  Build sources.list
# ============================================================
build_sources() {
    local proto="http"
    SOURCES_CONTENT=""
    SOURCES_CONTENT+="# Debian ${RELEASE_LABEL}\n"
    SOURCES_CONTENT+="# Generated by debian-sources.sh on $(date)\n"
    SOURCES_CONTENT+="# Mirror: ${MIRROR_LABEL}\n\n"
    SOURCES_CONTENT+="# Main repository\n"
    SOURCES_CONTENT+="deb ${proto}://${MIRROR}/debian ${RELEASE} ${COMPONENTS}\n"
    SOURCES_CONTENT+="deb-src ${proto}://${MIRROR}/debian ${RELEASE} ${COMPONENTS}\n"

    if [[ "$USE_SECURITY" == "y" ]]; then
        if [[ "$RELEASE" == "trixie" ]]; then
            SOURCES_CONTENT+="\n# Security\n"
            SOURCES_CONTENT+="deb ${proto}://security.debian.org/debian-security ${RELEASE}-security ${COMPONENTS}\n"
            SOURCES_CONTENT+="deb-src ${proto}://security.debian.org/debian-security ${RELEASE}-security ${COMPONENTS}\n"
        else
            SOURCES_CONTENT+="\n# Security (testing)\n"
            SOURCES_CONTENT+="deb ${proto}://security.debian.org/debian-security testing-security ${COMPONENTS}\n"
            SOURCES_CONTENT+="deb-src ${proto}://security.debian.org/debian-security testing-security ${COMPONENTS}\n"
        fi
    fi

    if [[ "$USE_UPDATES" == "y" ]]; then
        SOURCES_CONTENT+="\n# Updates\n"
        SOURCES_CONTENT+="deb ${proto}://${MIRROR}/debian ${RELEASE}-updates ${COMPONENTS}\n"
        SOURCES_CONTENT+="deb-src ${proto}://${MIRROR}/debian ${RELEASE}-updates ${COMPONENTS}\n"
    fi

    if [[ "$USE_BACKPORTS" == "y" ]]; then
        SOURCES_CONTENT+="\n# Backports\n"
        SOURCES_CONTENT+="deb ${proto}://${MIRROR}/debian ${RELEASE}-backports ${COMPONENTS}\n"
        SOURCES_CONTENT+="deb-src ${proto}://${MIRROR}/debian ${RELEASE}-backports ${COMPONENTS}\n"
    fi
}

# ============================================================
#  Preview + Apply
# ============================================================
show_preview_and_apply() {
    whiptail --title "Preview: ${SOURCES_FILE}" \
        --scrolltext --msgbox "$(echo -e "$SOURCES_CONTENT")" 24 $W

    if whiptail --title "$TITLE" \
        --yesno "Apply these changes to ${SOURCES_FILE}?" 8 $W; then

        if [[ -f "$SOURCES_FILE" ]]; then
            local bak="${BACKUP_DIR}/${BACKUP_PREFIX}$(date +%Y%m%d_%H%M%S)"
            cp "$SOURCES_FILE" "$bak"
        fi
        echo -e "$SOURCES_CONTENT" > "$SOURCES_FILE"

        if whiptail --title "$TITLE" \
            --yesno "sources.list written successfully.\n\nRun apt update now?" 9 $W; then
            clear
            apt update
            echo ""
            read -rp "  Press Enter to return..." _
        else
            whiptail --title "$TITLE" \
                --msgbox "Done! Sources configured successfully." 8 $W
        fi
    else
        whiptail --title "$TITLE" --msgbox "Cancelled. No changes made." 8 $W
    fi
}

# ============================================================
#  Configure sources — full wizard
# ============================================================
configure_sources() {
    RELEASE=""
    RELEASE_LABEL=""
    MIRROR=""
    MIRROR_LABEL=""
    COMPONENTS=""
    USE_SECURITY="y"
    USE_UPDATES="y"
    USE_BACKPORTS="n"
    SOURCES_CONTENT=""

    choose_release    || return
    choose_mirror     || return
    choose_components || return
    choose_extras     || return
    build_sources
    show_preview_and_apply
}

# ============================================================
#  Entry point
# ============================================================
main_menu
