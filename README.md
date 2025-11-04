# 🚀 Debian Router Setup Script

This repository contains a single, comprehensive Bash script (`install.sh`) designed to automate the configuration of a clean Debian (or Debian-based) system into a secure, dual-stack (IPv4/IPv6) home or small office router.

The script sets up key networking services including **PPPoE WAN**, **NAT/Masquerading**, **DNS (Unbound/Dnsmasq)**, **DHCPv4/DHCPv6**, and persistent **Firewall (iptables/ip6tables)** rules.

---

## 💖 Support and Donations

If this script has helped you set up your high-performance router, please consider supporting its development and maintenance. Every contribution is appreciated!

### Bitcoin (BTC) Wallet:

| Address | QR Code |
| :--- | :--- |
| **3Q1hjxTZiYookwLGUudKXAMq5JyKBWBUQd** | ![Bitcoin QR Code](https://raw.githubusercontent.com/faridx82-sys/debian-router/main/bitco.png) |

---

## ✨ Features

* **📦 Package Installation:** Automatically installs all required packages (`dnsmasq`, `radvd`, `wide-dhcpv6-client`, `unbound`, `pppoeconf`, etc.).
* **🌐 Dual-Stack Networking:** Configures static IPv4 and IPv6 ULA addresses on the LAN interface.
* **🔗 PPPoE WAN:** Sets up the necessary configuration for **PPPoE** connection (`dsl-provider`).
* **🔒 Secure DNS Resolution:** Deploys a recursive, validating **Unbound** resolver (listening on port 5353).
* **⚙️ Local DNS/DHCP:** Configures **Dnsmasq** for DHCPv4, DHCPv6, and local DNS caching, forwarding queries to Unbound.
* **🛡️ Firewall:** Creates robust, persistent **iptables** (with NAT/Masquerade) and **ip6tables** firewall rules.
* **🔄 Persistent Configuration:** Enables services to start on boot and uses **cron jobs** to restore firewall rules after reboot.
* **🚄 Kernel Tuning:** Enables **IP forwarding** via `sysctl` for both IPv4 and IPv6 traffic.

---

## 🌐 Default Networking Details

The script uses the following predetermined subnet configurations on the LAN interface:

| Detail | IPv4 (LAN) | IPv6 (LAN - ULA) |
| :--- | :--- | :--- |
| **Router IP** | **192.168.82.1** | **fd00:82::1** |
| **Subnet Range** | **192.168.82.0/24** | **fd00:82::/64** |
| **DHCP Range** | `192.168.82.100` to `192.168.82.240` | Stateless (SLAAC) plus DHCPv6 naming |

---

## 🛠️ Prerequisites

* A clean installation of **Debian 13 (Trixie)** (or similar distro tested with these versions of packages).
* Two network interfaces (one for WAN, one for LAN). The script expects the virtual WAN interface to be `ppp0`.
* The script must be run with **root privileges** (`sudo`).

---

## 🚀 Getting Started (Installation Steps)

The script runs in a batch process but starts with interactive prompts to gather necessary interface names.

### 1. Execute the Install Command

Use this single command to download, make the script executable, and start the installation. After reboot don't forget to run sudo pppoeconf to start the pppoe wizard.

```bash
sudo sh -c 'wget -O install.sh [https://raw.githubusercontent.com/faridx82-sys/debian-router/main/install.sh](https://raw.githubusercontent.com/faridx82-sys/debian-router/main/install.sh) && chmod +x install.sh && ./install.sh'


