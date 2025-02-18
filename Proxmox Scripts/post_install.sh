#!/bin/bash

# Licensed under the GNU General Public License v3.0
# Author: Grayson Morris (GraysonMor31)
# Inspiration of commands from: cjalas (r/homelab)
# Description: Post-install script for Proxmox VE 8.3+ to set up update repositories, remove subscription banner, install common packages, enable IOMMU, and configure PCIe passthrough.

# Proxmox Post-Install Script (ASCII Art)
echo -e "\e[1;32m"
cat << "EOF"
    ____ _    ________   ____   _____    ____             __     ____           __        ____
   / __ \ |  / / ____/  ( __ ) |__  /   / __ \____  _____/ /_   /  _/___  _____/ /_____ _/ / /
  / /_/ / | / / __/    / __  |  /_ <   / /_/ / __ \/ ___/ __/   / // __ \/ ___/ __/ __ `/ / / 
 / ____/| |/ / /___   / /_/ / ___/ /  / ____/ /_/ (__  ) /_   _/ // / / (__  ) /_/ /_/ / / /  
/_/     |___/_____/   \____(_)____/  /_/    \____/____/\__/  /___/_/ /_/____/\__/\__,_/_/_/   
EOF
echo -e "\e[0m"

# Enable the Proxmox No-Subscription Repository for Sources and Ceph
echo "Configuring Proxmox No-Subscription Repository..."

# Disable Enterprise Sources Repo and append No-Subscription Repo
sed -i "s/^deb/#deb/g" /etc/apt/sources.list.d/pve-enterprise.list
grep -qxF "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" /etc/apt/sources.list.d/pve-enterprise.list || echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" >> /etc/apt/sources.list.d/pve-enterprise.list

# Disable Enterprise Ceph Repo and append No-Subscription Ceph Repo
sed -i "s/^deb/#deb/g" /etc/apt/sources.list.d/ceph.list
grep -qxF "deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription" /etc/apt/sources.list.d/ceph.list || echo "deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription" >> /etc/apt/sources.list.d/ceph.list

# Update and upgrade the package lists
apt update && apt dist-upgrade -y
echo "Successfully set up Proxmox No-Subscription Repository!"

# Remove the subscription banner (nag)
echo "Removing Subscription Banner..."
cp /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.bak
sed -i "s|if (data.status !== 'Active')|if (false)|g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
systemctl restart pveproxy.service
echo "Successfully removed Subscription Banner!"

# Install common packages
echo "Installing common packages..."
apt install -y htop curl wget git net-tools

# Configure PCIe Passthrough
echo -e "\e[1;32m"
cat << "EOF"
    ____  __________        ____                  __  __                           __  
   / __ \/ ____/  _/__     / __ \____ ___________/ /_/ /_  _________  __  ______ _/ /_ 
  / /_/ / /    / // _ \   / /_/ / __ `/ ___/ ___/ __/ __ \/ ___/ __ \/ / / / __ `/ __ \
 / ____/ /____/ //  __/  / ____/ /_/ (__  |__  ) /_/ / / / /  / /_/ / /_/ / /_/ / / / /
/_/    \____/___/\___/  /_/    \__,_/____/____/\__/_/ /_/_/   \____/\__,_/\__, /_/ /_/ 
                                                                         /____/        
EOF
echo -e "\e[0m"

# Enable IOMMU
echo "Enabling IOMMU..."
if ! grep -q "intel_iommu=on" /etc/default/grub; then
    sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="\)/\1intel_iommu=on iommu=pt pcie_acs_override=downstream,multifunction nofb nomodeset video=vesafb:off,efifb:off /' /etc/default/grub
fi
update-grub

# Load VFIO Kernel Modules
echo "Loading VFIO Kernel Modules..."
cat <<EOF >> /etc/modules
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
EOF

depmod -a

# IOMMU Interrupt Remapping
echo "Configuring IOMMU Interrupt Remapping..."
echo -e "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/iommu_unsafe_interrupts.conf
echo -e "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf

# Blacklist GPU Drivers
echo "Blacklisting GPU Drivers..."
cat <<EOF > /etc/modprobe.d/blacklist.conf
blacklist radeon
blacklist nouveau
blacklist nvidia
EOF

# Add GPU to VFIO
echo "Adding GPU to VFIO..."

# Get GPU Address/ID dynamically
GPU_ADDRESS=$(lspci -Dn | grep -i "VGA compatible controller" | grep -i nvidia | awk '{print $1}')
AUDIO_ADDRESS=$(lspci -Dn | grep -i "Audio device" | grep -i nvidia | awk '{print $1}')
GPU_ID=$(lspci -n -s $GPU_ADDRESS | awk '{print $3}')
AUDIO_ID=$(lspci -n -s $AUDIO_ADDRESS | awk '{print $3}')

echo "GPU Address: $GPU_ADDRESS"
echo "GPU Audio Address: $AUDIO_ADDRESS"

# Ensure variables are set before continuing
if [[ -n "$GPU_ID" && -n "$AUDIO_ID" ]]; then
    echo -e "options vfio-pci ids=$GPU_ID,$AUDIO_ID" > /etc/modprobe.d/vfio.conf
    echo "VFIO configuration updated."
else
    echo "Error: Could not detect GPU or Audio IDs. Check lspci output manually."
    exit 1
fi

# Update initramfs
echo "Updating initramfs..."
update-initramfs -u

# Reboot to apply changes
echo "Rebooting in 10 seconds... Press Ctrl+C to cancel."
sleep 10
reboot -f