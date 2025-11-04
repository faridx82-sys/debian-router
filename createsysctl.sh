#!/bin/bash
# createsysctl.sh
# Purpose: Create /etc/sysctl.d/router.conf with forwarding and IPv6 settings

set -e

echo "======================================="
echo " Create Sysctl Configuration"
echo "======================================="

# Ensure root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Ask for LAN interface name
read -rp "Enter LAN interface name [default: ens18]: " LAN_IF
LAN_IF=${LAN_IF:-ens18}

SYSCTL_FILE="/etc/sysctl.d/router.conf"

echo "[*] Creating $SYSCTL_FILE ..."
cat <<EOF > "$SYSCTL_FILE"
net.ipv4.ip_forward=1
# Enable IPv6 forwarding
net.ipv6.conf.all.forwarding=1
net.ipv6.conf.default.forwarding=1

# Allow PPPoE WAN to still accept RA (IPv6 from ISP)
net.ipv6.conf.ppp0.accept_ra=2

# LAN interface should advertise IPv6 (optional)
net.ipv6.conf.$LAN_IF.accept_ra=0
EOF

chmod 644 "$SYSCTL_FILE"

echo "[+] $SYSCTL_FILE created successfully."

# Apply sysctl settings immediately
echo "[*] Applying sysctl settings..."
sysctl --system

echo "======================================="
echo "Sysctl configuration applied successfully!"
echo "LAN interface: $LAN_IF"
echo "======================================="
