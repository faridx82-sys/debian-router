# 🚀 Debian Router Setup Script

This repository contains a single, comprehensive Bash script (`install.sh`) designed to automate the configuration of a clean Debian (or Debian-based) system into a secure, dual-stack (IPv4/IPv6) home or small office router.

The script sets up key networking services including **PPPoE WAN**, **NAT/Masquerading**, **DNS (Unbound/Dnsmasq)**, **DHCPv4/DHCPv6**, and persistent **Firewall (iptables/ip6tables)** rules.

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

## 🛠️ Prerequisites

* A clean installation of **Debian 11 (Bullseye)** or **Debian 12 (Bookworm)** (or similar distro).
* Two network interfaces (one for WAN, one for LAN). The script assumes the physical WAN interface is `ens19` and the virtual WAN interface is `ppp0`.
* The script must be run with **root privileges** (`sudo`).

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone [https://github.com/faridx82-sys/debian-router.git](https://github.com/faridx82-sys/debian-router.git)
cd debian-router
