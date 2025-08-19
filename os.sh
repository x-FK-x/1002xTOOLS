#!/bin/bash

# Stoppe das Skript, wenn ein Fehler auftritt
set -e

# Ziel-Festplatte
DISK="/dev/sda"

# Partitionen
ROOT_PART="${DISK}1"
SWAP_PART="${DISK}2"
HOME_PART="${DISK}3"

# Partitionierung
echo "Erstelle Partitionstabelle auf ${DISK}..."
parted ${DISK} --script mklabel gpt

# Erstelle Root-Partition (20 GB)
echo "Erstelle Root-Partition (${ROOT_PART})..."
parted ${DISK} --script mkpart primary ext4 1MiB 20GiB

# Erstelle Swap-Partition (2 GB)
echo "Erstelle Swap-Partition (${SWAP_PART})..."
parted ${DISK} --script mkpart primary linux-swap 20GiB 22GiB

# Erstelle Home-Partition (Rest der Festplatte)
echo "Erstelle Home-Partition (${HOME_PART})..."
parted ${DISK} --script mkpart primary ext4 22GiB 100%

# Aktualisiere die Partitionstabelle
partprobe ${DISK}

# Formatieren der Partitionen
echo "Formatiere Root-Partition (${ROOT_PART})..."
mkfs.ext4 ${ROOT_PART}

echo "Formatiere Swap-Partition (${SWAP_PART})..."
mkswap ${SWAP_PART}
swapon ${SWAP_PART}

echo "Formatiere Home-Partition (${HOME_PART})..."
mkfs.ext4 ${HOME_PART}

# Mounten der Partitionen
echo "Mounten der Root-Partition (${ROOT_PART}) auf /mnt..."
mount ${ROOT_PART} /mnt

echo "Mounten der Home-Partition (${HOME_PART}) auf /mnt/home..."
mkdir -p /mnt/home
mount ${HOME_PART} /mnt/home

# Swap aktivieren
swapon ${SWAP_PART}

# Installieren von Basispaketen (hier als Beispiel für Ubuntu/Debian)
echo "Installiere Basispakete auf /mnt..."
debootstrap stable /mnt http://deb.debian.org/debian/

# Chroot in das neue System
echo "Wechsel in das neue System..."
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
mount --bind /run /mnt/run

chroot /mnt /bin/bash <<EOF

# Installiere GRUB
echo "Installiere GRUB..."
apt update
apt install -y grub-pc

# Installiere das Basis-System
echo "Installiere Kernel und andere Basis-Pakete..."
apt install -y linux-image-amd64 sudo

# Installiere den Bootloader
echo "Installiere GRUB auf ${DISK}..."
grub-install ${DISK}

# Erstelle die GRUB-Konfiguration
update-grub

EOF

# Bereinigen und Mount-Punkte trennen
umount -R /mnt

echo "Fertig! Dein System ist jetzt installiert. Du kannst jetzt von der Festplatte starten."

