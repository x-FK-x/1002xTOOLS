#!/bin/bash

# === Logged-in user HOME detection ===
REALUSER=$(logname 2>/dev/null || echo "$SUDO_USER")
USERHOME=$(eval echo "~$REALUSER")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === Version detection ===
if [[ -d /etc/modos ]]; then
    VERSION_DIR="/etc/modos"
elif [[ -d /etc/dodos ]]; then
    VERSION_DIR="/etc/dodos"
else
    whiptail --title "Error" --msgbox "No version file found (/etc/modos or /etc/dodos)." 10 50
    exit 1
fi

DEBUI="$VERSION_DIR/debui.sh"
LIST="$SCRIPT_DIR/list.txt"

DESKTOP_DIR="$USERHOME/Desktop"
SHORTCUT_PREF_FILE="$USERHOME/.1002xtools_shortcut_preference"

if [[ ! -f "$LIST" ]]; then
    whiptail --title "Error" --msgbox "Tool list not found:\n$LIST" 10 60
    exit 1
fi

mkdir -p "$DESKTOP_DIR"

declare -A STATUS

# === 1002xTOOLS as fixed first entry (preference-aware) ===
TOOLS_DESK="no"
[[ -f "$DESKTOP_DIR/1002xTOOLS.desktop" ]] && TOOLS_DESK="yes"

TOOLS_PREF="unknown"
[[ -f "$SHORTCUT_PREF_FILE" ]] && TOOLS_PREF=$(cat "$SHORTCUT_PREF_FILE")

STATUS["1002xTOOLS"]="yes|$TOOLS_DESK"
MENU_ITEMS=("1002xTOOLS" "1002xTOOLS — Internal system tools (desktop: $TOOLS_DESK, pref: $TOOLS_PREF)" "OFF")

# === Scan tools and collect menu data ===
while IFS= read -r TOOL || [[ -n "$TOOL" ]]; do
    [[ -z "$TOOL" ]] && continue

    INSTALLED="no"
    DESK="no"

    command -v "$TOOL" &>/dev/null && INSTALLED="yes"
    [[ -f "$DESKTOP_DIR/$TOOL.desktop" ]] && DESK="yes"

    STATUS["$TOOL"]="$INSTALLED|$DESK"

    LABEL="$TOOL (installed: $INSTALLED, desktop: $DESK)"
    MENU_ITEMS+=("$TOOL" "$LABEL" "OFF")

done < "$LIST"


# === Multi selection menu ===
SELECTIONS=$(whiptail --title "Desktop Entry Manager" \
    --checklist "Select tools to sync (create/remove desktop entries):" \
    25 80 15 \
    "${MENU_ITEMS[@]}" \
    3>&1 1>&2 2>&3)

[[ $? -ne 0 ]] && exit 0


# === Icon Finder ===
find_icon() {
    local TOOL="$1"
    local ICON=""

    SEARCH_PATHS=(
        "/usr/share/icons/hicolor/*/apps"
        "/usr/share/icons/*/*/apps"
        "/usr/share/pixmaps"
        "/usr/share/icons"
    )

    for DIR in "${SEARCH_PATHS[@]}"; do
        ICON_FILE=$(find $DIR -maxdepth 1 -type f \
            \( -name "${TOOL}.png" -o -name "${TOOL}.svg" \) 2>/dev/null | head -n 1)

        if [[ -n "$ICON_FILE" ]]; then
            ICON="$ICON_FILE"
            break
        fi
    done

    [[ -z "$ICON" ]] && ICON="utilities-terminal"
    echo "$ICON"
}


# === Create desktop entry ===
create_desktop_entry() {
    local NAME="$1"
    local FILE="$DESKTOP_DIR/$NAME.desktop"
    local ICON
    ICON=$(find_icon "$NAME")

cat <<EOF > "$FILE"
[Desktop Entry]
Name=$NAME
Exec=$NAME
Icon=$ICON
Terminal=false
Type=Application
Categories=Utility;
EOF

    chmod +x "$FILE"
    chown "$REALUSER":"$REALUSER" "$FILE"
}

# === Create 1002xTOOLS desktop entry ===
create_tools_entry() {
    local FILE="$DESKTOP_DIR/1002xTOOLS.desktop"

cat <<EOF > "$FILE"
[Desktop Entry]
Name=1002xTOOLS
Exec=$DEBUI
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=System;
EOF

    chmod +x "$FILE"
    chown "$REALUSER":"$REALUSER" "$FILE"
    echo "yes" > "$SHORTCUT_PREF_FILE"
    chown "$REALUSER":"$REALUSER" "$SHORTCUT_PREF_FILE"
}


# === Process selected items ===
for TOOL in $SELECTIONS; do
    TOOL=$(echo "$TOOL" | tr -d '"')

    HAS_DESK=$(echo "${STATUS[$TOOL]}" | cut -d '|' -f2)
    DESK_FILE="$DESKTOP_DIR/$TOOL.desktop"

    # 1002xTOOLS — special handling with preference file
    if [[ "$TOOL" == "1002xTOOLS" ]]; then
        if [[ "$HAS_DESK" == "yes" ]]; then
            rm -f "$DESK_FILE"
            echo "no" > "$SHORTCUT_PREF_FILE"
            chown "$REALUSER":"$REALUSER" "$SHORTCUT_PREF_FILE"
            whiptail --title "Removed" --msgbox "Removed desktop entry for 1002xTOOLS." 10 50
        else
            create_tools_entry
            whiptail --title "Created" --msgbox "Created desktop entry for 1002xTOOLS." 10 50
        fi
        continue
    fi

    INSTALLED=$(echo "${STATUS[$TOOL]}" | cut -d '|' -f1)

    if [[ "$INSTALLED" == "no" ]]; then
        whiptail --title "Skipping" --msgbox \
            "'$TOOL' is not installed. Skipping." 10 50
        continue
    fi

    if [[ "$HAS_DESK" == "yes" ]]; then
        rm -f "$DESK_FILE"
        whiptail --title "Removed" --msgbox \
            "Removed desktop entry for '$TOOL'." 10 50
    else
        create_desktop_entry "$TOOL"
        whiptail --title "Created" --msgbox \
            "Created desktop entry for '$TOOL'." 10 50
    fi
done

whiptail --title "Done" --msgbox "All selected tools processed." 10 50
exit 0
