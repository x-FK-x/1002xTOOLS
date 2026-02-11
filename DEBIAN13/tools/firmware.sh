#!/bin/bash


# Funktion zur Installation von isenkram-cli und Firmware
install_firmware_tools() {
    echo "Install isenkram-cli..."
    sudo apt update
    sudo apt install -y isenkram-cli
}

# Funktion zur automatischen Installation der Firmware
auto_install_firmware() {
    echo "Look for missing firmware und install those..."
    sudo isenkram-autoinstall-firmware
}

# Hauptskript
echo "Start Firmware-Installations for Debian 13..."

install_firmware_tools
auto_install_firmware

echo "Firmware-Installation finished!"
#DODOS - 
