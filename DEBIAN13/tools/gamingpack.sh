#!/bin/bash
set -u

command -v whiptail >/dev/null 2>&1 || { echo “whiptail not found. Install it with: sudo apt install whiptail”; exit 1; }

ALWAYS_PKGS="gamemode libgamemode0 libgamemodeauto0"
CHECK_PKGS="joystick jstest-gtk antimicrox xboxdrv steam-devices lutris winehq-stable steam discord $ALWAYS_PKGS"

pkg_installed() {
dpkg-query -W -f='${Status}' “$1” 2>/dev/null | grep -q “install ok installed”
}

state() {
if pkg_installed “$1”; then echo OFF; else echo ON; fi
}

if ! whiptail --title “Gamingpack” --yesno “Install the Gamingpack?” 8 45; then
echo “Installation canceled.”
exit 0
fi

echo “Checking system...”
missing=""
for p in $CHECK_PKGS; do
pkg_installed “$p" || missing="$missing $p”
done
if [ -n “$missing” ]; then
echo “Missing packages:$missing”
else
echo “All packages are already installed.”
fi
if dpkg --print-foreign-architectures | grep -qx i386; then
echo “i386 architecture: enabled”
else
echo “i386 architecture: not enabled”
fi

choices=$(whiptail --title “Gamingpack” --separate-output --checklist
“Select software to install (gamemode is always installed):” 20 72 8
“controllers” “Joystick tools, antimicrox, xboxdrv, steam-devices” “$(state joystick)”
“lutris” “Lutris game manager” “$(state lutris)”
“wine” “WineHQ stable” “$(state winehq-stable)”
“steam” “Steam” “$(state steam)”
“discord” “Discord” “$(state discord)”
3>&1 1>&2 2>&3) || { echo “Installation canceled.”; exit 0; }

PKGS="$ALWAYS_PKGS"
NEED_I386=0
WANT_STEAM=0
WANT_DISCORD=0

for c in $choices; do
case $c in
controllers) PKGS="$PKGS joystick jstest-gtk antimicrox xboxdrv steam-devices" ;;
lutris) PKGS="$PKGS lutris" ;;
wine) PKGS="$PKGS winehq-stable"; NEED_I386=1 ;;
steam) PKGS="$PKGS steam"; NEED_I386=1; WANT_STEAM=1 ;;
discord) WANT_DISCORD=1 ;;
esac
done

echo “Packages to install:$PKGS”
if [ “$WANT_DISCORD” -eq 1 ] && ! pkg_installed discord; then
echo “Discord: will be downloaded and installed separately”
fi

if ! whiptail --title “Gamingpack” --yesno “Proceed with installation?” 8 45; then
echo “Installation canceled.”
exit 0
fi

echo “Starting installation...”

if [ “$NEED_I386” -eq 1 ] && ! dpkg --print-foreign-architectures | grep -qx i386; then
sudo dpkg --add-architecture i386
fi

if [ “$WANT_STEAM” -eq 1 ]; then
echo “deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware” | sudo tee /etc/apt/sources.list.d/steam-temp.list >/dev/null
fi

sudo apt update || { echo “apt update failed”; exit 1; }
sudo apt install -y $PKGS || { echo “apt install failed”; exit 1; }

if [ “$WANT_DISCORD” -eq 1 ] && ! pkg_installed discord; then
wget -q “https://discord.com/api/download?platform=linux&format=deb” -O /tmp/discord.deb || { echo “Discord download failed”; exit 1; }
sudo apt install -y /tmp/discord.deb || { echo “Discord install failed”; exit 1; }
rm -f /tmp/discord.deb
fi

if [ “$WANT_STEAM” -eq 1 ]; then
sudo rm -f /etc/apt/sources.list.d/steam-temp.list
sudo apt update
fi

echo “Installation finished.”
if [ “$WANT_STEAM” -eq 1 ]; then
echo “Use the Steam installer to get Steam.”
fi
exit 0
