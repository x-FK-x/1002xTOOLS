#!/bin/bash

set -e

echo "=== Debian Gaming Setup Script ==="

# 1. System aktualisieren
apt update && apt upgrade -y

# 4. Wichtige Systempakete installieren
apt install -y \
    curl wget git unzip p7zip-full \
    firmware-linux firmware-misc-nonfree firmware-realtek \
    libgl1-mesa-driver mesa-vulkan-drivers firefox-esr

# 5. Multiarch für Wine/Steam
dpkg --add-architecture i386
apt update

# 6. Controller- und Gamepad-Unterstützung
apt install -y \
    joystick jstest-gtk antimicrox \
    xboxdrv steam-devices

# 7. Steam installieren
wget https://cdn.fastly.steamstatic.com/client/installer/steam.deb
apt install -y ./steam.deb
rm ./steam.deb

# 8. Wine + Proton Dependencies
apt install -y \
    wine64 wine32 \
    libwine libwine:i386 \
    libvulkan1 libvulkan1:i386

# 9. Lutris installieren
echo -e "Types: deb\nURIs: https://download.opensuse.org/repositories/home:/strycore/Debian_12/\nSuites: ./\nComponents: \nSigned-By: /etc/apt/keyrings/lutris.gpg" | sudo tee /etc/apt/sources.list.d/lutris.sources > /dev/null
wget -q -O- https://download.opensuse.org/repositories/home:/strycore/Debian_12/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/lutris.gpg
apt update
apt install lutris -y

# 10. Heroic Games Launcher (aktuelle .deb von GitHub)
echo "Installing Heroic Games Launcher..."
HEROIC_DEB=$(curl -s https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest \
  | grep browser_download_url \
  | grep 'amd64.deb' \
  | cut -d '"' -f 4)

wget "$HEROIC_DEB" -O /tmp/heroic.deb
apt install -y /tmp/heroic.deb
rm /tmp/heroic.deb

# 11. Gamemode für Performance-Tuning
apt install -y gamemode libgamemode0 libgamemodeauto0



echo "=== Setup Complete ==="
echo "Reboot to enter KDE and enjoy gaming!"

#____

set -e

echo "=== Replacing KDE File Manager with Caja system-wide ==="

# 1. Entferne Dolphin und andere KDE-Apps
echo "Removing Dolphin and optional KDE apps..."
apt purge -y \
    dolphin \
    kwrite \
    kwalletmanager \
    konqueror \
    khelpcenter \
    sweeper \
    kget \
    kdeconnect \
    dragonplayer \
    okular || true

apt autoremove -y

# 2. Installiere Caja
echo "Installing Caja..."
apt install -y caja

# 3. Setze Caja global als Standard-Dateimanager
echo "Setting Caja as default file manager system-wide..."
mkdir -p /etc/xdg
cat > /etc/xdg/mimeapps.list <<EOF
[Default Applications]
inode/directory=caja.desktop
EOF

echo "=== Done. Caja is now the default file manager for all users. ==="

#---


