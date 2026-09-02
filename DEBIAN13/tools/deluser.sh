#!/bin/bash

USERNAME=$(whiptail --inputbox "Enter the username to delete:" 10 50 3>&1 1>&2 2>&3) || exit 1

if ! id "$USERNAME" &>/dev/null; then
  whiptail --title "Delete User" --msgbox "User '$USERNAME' does not exist." 10 50
  exit 1
fi

whiptail --title "Confirm Deletion" --yesno "Do you really want to delete user '$USERNAME' and their home directory?" 10 60
if [[ $? -ne 0 ]]; then
  exit 0
fi

# === Autologin-Dateien prüfen und ggf. bereinigen ===
if [[ -f /etc/lightdm/lightdm.conf.d/50-autologin.conf ]] && grep -q "autologin-user=$USERNAME" /etc/lightdm/lightdm.conf.d/50-autologin.conf; then
  sudo sed -i "/autologin-user=$USERNAME/d" /etc/lightdm/lightdm.conf.d/50-autologin.conf
fi

sudo sed -i "/^$USERNAME\s\+ALL=(ALL:ALL) ALL$/d" /etc/sudoers

sudo deluser "$USERNAME"


#Home entfernen 
sudo rm -r /home/$USERNAME

# === Abschlussmeldung ===
whiptail --title "User Deleted" --msgbox "User '$USERNAME' has been removed successfully (including home directory and possible autologin)." 10 50
#DODOS - DownTown1002xCollection of Debian OS

