#!/bin/bash

# Function to install isenkram-cli and your core bundle safety net
install_firmware_tools() {
    echo "=================================================="
    echo "🔄 Updating package lists & installing core tools..."
    echo "=================================================="
    sudo apt update
    
    # 1. Install your requested universal safety net bundle (Covers Intel & Realtek Bluetooth!)
    echo "📦 Installing core firmware and CPU microcode bundle..."
    sudo apt install -y firmware-linux firmware-misc-nonfree firmware-realtek firmware-iwlwifi intel-microcode amd64-microcode
    
    # 2. Install the hardware scanning tool
    echo "📦 Installing isenkram-cli..."
    sudo apt install -y isenkram-cli
}

# Function to automatically scan and install missing firmware via isenkram
auto_install_firmware() {
    echo -e "\n=================================================="
    echo "🔍 Scanning for missing hardware firmware..."
    echo "=================================================="
    sudo isenkram-autoinstall-firmware
}

# Function to check the GPU and install appropriate drivers/acceleration
check_gpu_drivers() {
    echo -e "\n=================================================="
    echo "🎨 Checking Graphics Card (GPU)..."
    echo "=================================================="
    GPU_INFO=$(lspci -nn | grep -E -i "vga|3d|display")
    echo "Detected: $GPU_INFO"

    if echo "$GPU_INFO" | grep -iq "nvidia"; then
        echo "🟢 NVIDIA GPU detected. Triggering driver configuration..."
        sudo apt install -y nvidia-detect
        if command -v nvidia-detect >/dev/null 2>&1; then
            sudo apt install -y $(nvidia-detect | grep -E "nvidia-driver|nvidia-legacy")
        else
            sudo apt install -y nvidia-driver
        fi
    elif echo "$GPU_INFO" | grep -iq "amd\|ati"; then
        echo "🟢 AMD/ATI GPU detected. Ensuring accelerated Mesa drivers..."
        sudo apt install -y libglx-mesa0 mesa-vulkan-drivers
    elif echo "$GPU_INFO" | grep -iq "intel"; then
        echo "🟢 Intel GPU detected. Enabling hardware video acceleration..."
        sudo apt install -y intel-media-va-driver-non-free mesa-vulkan-drivers
    fi
}

# Function to ensure Bluetooth stack and services are installed and active
configure_bluetooth() {
    echo -e "\n=================================================="
    echo "🌐 Checking and configuring Bluetooth Stack..."
    echo "=================================================="
    
    # Install the official Linux Bluetooth stack and a graphical manager (blueman)
    echo "📦 Installing bluez and bluetooth management tools..."
    sudo apt install -y bluez bluez-tools blueman
    
    # Enable and start the background service
    echo "⚙️ Enabling and starting Bluetooth system service..."
    sudo systemctl enable bluetooth
    sudo systemctl start bluetooth
    
    echo "🟢 Bluetooth service is now active and ready."
}

# Main Script Execution
echo "🚀 Starting Firmware-Installation Script for Debian..."

install_firmware_tools
auto_install_firmware
check_gpu_drivers
configure_bluetooth

echo -e "\n=================================================="
echo "✅ Firmware-Installation finished!"
echo "🔄 Please reboot your system ('sudo reboot') to apply changes."
echo "=================================================="
