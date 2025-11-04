#!/bin/bash
# installpackage.sh
# Purpose: Automatically install required network/router packages on Debian

set -e

echo "======================================="
echo " Install Required Packages"
echo "======================================="

# Ensure root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "[*] Updating package list..."
apt update -y

echo "[*] Installing packages (non-interactively)..."

apt install -y dnsmasq \
  dhcpcd5 \
  wide-dhcpv6-client \
  radvd \
  pppoeconf \
  iptables \
  unbound \
  ndisc6 \
  sudo \
  curl

echo "======================================="
echo "[+] All packages installed successfully!"
echo "======================================="
