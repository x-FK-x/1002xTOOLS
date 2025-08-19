#!/bin/bash

# Stoppe das Skript, wenn ein Fehler auftritt
set -e

# Ziel-Festplatte
DISK="/dev/sda"

# 1. Festplatte vollständig löschen (alle Partitionen entfernen)
echo "Lösche alle Partitionen auf ${DISK}..."
sudo parted ${DISK} --script mklabel gpt

# 2. Partitionierung mit parted (GPT)
echo "Erstelle Partitionen auf ${DISK}..."

# Root-Partition: Erste Partition (größter Teil der Festplatte)
echo "Erstelle Root-Partition..."
sudo parted ${DISK} --script mkpart primary ext4 1MiB 100%

# Hole die Gesamtgröße der Festplatte
DISK_SIZE=$(sudo parted ${DISK} unit GiB print | grep "Disk ${DISK}" | awk '{print $3}' | sed 's/GiB//')

# Berechne die Größe der Swap-Partition (z. B. 4 GB oder 50% der Festplatte, wenn sie weniger als 4 GB groß ist)
SWAP_SIZE=$((DISK_SIZE < 4 ? 2 : 4))  # Falls die Festplatte kleiner als 4 GB ist, wird die Swap-Partition auf 2 GB gesetzt

# Berechne den verbleibenden Platz für die Home-Partition
ROOT_PART="${DISK}1"
SWAP_PART="${DISK}2"
HOME_PART="${DISK}3"

# Erstelle eine Swap-Partition
echo "Erstelle Swap-Partition von ${SWAP_SIZE} GB..."
sudo parted ${DISK} --script mkpart primary linux-swap 100% 100%

# Aktualisiere die Partitionstabelle
sudo partprobe ${DISK}

# 3. Formatieren der Partitionen
echo "Formatiere Root-Partition (${ROOT_PART})..."
sudo mkfs.ext4 ${ROOT_PART}

echo "Formatiere Swap-Partition (${SWAP_PART})..."
sudo mkswap ${SWAP_PART}
sudo swapon ${SWAP_PART}

# 4. Mounten der Partitionen
echo "Mounten der Root-Partition (${ROOT_PART}) auf /mnt..."
sudo mount ${ROOT_PART} /mnt

# 5. Basissystem installieren (Debian/Ubuntu basierte Systeme)
echo "Installiere Basispakete auf /mnt..."
sudo debootstrap stable /mnt http://deb.debian.org/debian/

# 6. Chroot in das neue System
echo "Wechsel in das neue System..."
sudo mount --bind /dev /mnt/dev
sudo mount --bind /proc /mnt/proc
sudo mount --bind /sys /mnt/sys
sudo mount --bind /run /mnt/run

sudo chroot /mnt /bin/bash <<EOF

# 7. GRUB und andere Pakete installieren
echo "Installiere GRUB und andere Pakete..."
sudo apt update
sudo apt install -y grub-pc linux-image-amd64 sudo

# 8. Installiere den Bootloader (GRUB)
echo "Installiere GRUB auf ${DISK}..."
sudo grub-install ${DISK}

# 9. GRUB-Konfiguration erstellen
sudo update-grub

EOF

# 10. Bereinigen und Mount-Punkte trennen
sudo umount -R /mnt

# 11. Fertig! Das System ist nun installiert.
echo "Fertig! Dein System ist jetzt installiert. Du kannst jetzt von der Festplatte starten."
