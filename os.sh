#!/bin/bash

# Stoppe das Skript, wenn ein Fehler auftritt
set -e

# Ziel-Festplatte
DISK="/dev/sda"

# Partitionen
ROOT_PART="${DISK}1"
SWAP_PART="${DISK}2"
HOME_PART="${DISK}3"

# 1. Installiere parted (falls noch nicht installiert)
echo "Installiere parted..."
apt update
apt install -y parted

# 2. Festplatte vollständig löschen (alle Partitionen entfernen)
echo "Lösche alle Partitionen auf ${DISK}..."
parted ${DISK} --script mklabel gpt

# 3. Partitionierung mit parted (GPT)
echo "Erstelle Partitionen auf ${DISK}..."
# Root-Partition: 20 GB
parted ${DISK} --script mkpart primary ext4 1MiB 20GiB
# Swap-Partition: 2 GB
parted ${DISK} --script mkpart primary linux-swap 20GiB 22GiB
# Home-Partition: Rest des Speicherplatzes
parted ${DISK} --script mkpart primary ext4 22GiB 100%

# Aktualisiere die Partitionstabelle
partprobe ${DISK}

# 4. Formatieren der Partitionen
echo "Formatiere Root-Partition (${ROOT_PART})..."
mkfs.ext4 ${ROOT_PART}

echo "Formatiere Swap-Partition (${SWAP_PART})..."
mkswap ${SWAP_PART}
swapon ${SWAP_PART}

echo "Formatiere Home-Partition (${HOME_PART})..."
mkfs.ext4 ${HOME_PART}

# 5. Mounten der Partitionen
echo "Mounten der Root-Partition (${ROOT_PART}) auf /mnt..."
mount ${ROOT_PART} /mnt

echo "Mounten der Home-Partition (${HOME_PART}) auf /mnt/home..."
mkdir -p /mnt/home
mount ${HOME_PART} /mnt/home

# 6. Basissystem installieren (Debian/Ubuntu basierte Systeme)
echo "Installiere Basispakete auf /mnt..."
debootstrap stable /mnt http://deb.debian.org/debian/

# 7. Chroot in das neue System
echo "Wechsel in das neue System..."
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
mount --bind /run /mnt/run

chroot /mnt /bin/bash <<EOF

# 8. GRUB und andere Pakete installieren
echo "Installiere GRUB und andere Pakete..."
apt update
apt install -y grub-pc linux-image-amd64 sudo

# 9. Installiere den Bootloader (GRUB)
echo "Installiere GRUB auf ${DISK}..."
grub-install ${DISK}

# 10. GRUB-Konfiguration erstellen
update-grub

EOF

# 11. Bereinigen und Mount-Punkte trennen
umount -R /mnt

# 12. Fertig! Das System ist nun installiert.
echo "Fertig! Dein System ist jetzt installiert. Du kannst jetzt von der Festplatte starten."

