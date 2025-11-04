#!/bin/bash
# config.sh: Deploy all router configurations and enable services for boot.

# --- User Input Prompt ---
echo "--- Configuration Script for Router Services (DNSmasq, RADVD, DHCP6C, Unbound, & Networking) ---"
read -r -p "Enter the **LAN interface name** (e.g., ens18, eth0): " LAN_INTERFACE
# ---

INTERFACES_FILE="/etc/network/interfaces"
DNSMASQ_CONFIG_FILE="/etc/dnsmasq.d/router.conf"
RADVD_CONFIG_FILE="/etc/radvd.conf"
DHCP6C_CONFIG_FILE="/etc/wide-dhcpv6/dhcp6c.conf"
UNBOUND_CONFIG_FILE="/etc/unbound/unbound.conf.d/router.conf"

echo ""
echo "Using LAN interface: **${LAN_INTERFACE}**"
echo "--------------------------------------------------------"

# --- Section 1: Deploy /etc/network/interfaces Configuration ---
echo "1. Deploying network interfaces configuration to ${INTERFACES_FILE}..."

# Note: LAN_INTERFACE is substituted for ens18 for the static address definitions.
cat << EOF | sudo tee "${INTERFACES_FILE}" > /dev/null
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary LAN network interface
allow-hotplug ${LAN_INTERFACE}
iface ${LAN_INTERFACE} inet static
address 192.168.82.1
netmask 255.255.255.0

iface ${LAN_INTERFACE} inet6 static
address fd00:82::1
netmask 64

# PPPoE setup (requires pppoeconf)
auto dsl-provider
iface dsl-provider inet ppp
pre-up /bin/ip link set ens19 up # line maintained by pppoeconf
provider dsl-provider

# WAN Physical Interface (set to manual as pppoeconf will handle it)
auto ens19
iface ens19 inet manual
EOF

echo "✅ Network interfaces configuration saved."

# --- Section 2: Deploy WIDE-DHCPV6-CLIENT Configuration ---
echo ""
echo "2. Deploying WIDE-DHCPV6-CLIENT configuration to ${DHCP6C_CONFIG_FILE}..."

# Ensure the directory exists
sudo mkdir -p /etc/wide-dhcpv6

cat << EOF | sudo tee "${DHCP6C_CONFIG_FILE}" > /dev/null
# ==========================================
# wide-dhcpv6-client configuration
# For PPPoE WAN + IPv6 Prefix Delegation
# ==========================================

# Request IPv6 address and prefix delegation from ISP
interface ppp0 {
    send ia-na 0;          # Request an IPv6 address for this interface
    send ia-pd 1;          # Request a delegated prefix
    request domain-name-servers;
    request domain-name;
    script "/etc/wide-dhcpv6/dhcp6c-script"; # Default hook script
};

# Define how to handle the delegated prefix
id-assoc pd 1 {
    prefix-interface ${LAN_INTERFACE} {
        sla-id 0;            # Subnet ID within the delegated prefix
        sla-len 0;           # ISP usually gives /56 or /60, we use first /64
    };
};

# Store obtained address
id-assoc na 0 { };
EOF

echo "✅ wide-dhcpv6-client configuration saved."

# --- Section 3: Deploy DNSmasq Configuration ---
echo ""
echo "3. Deploying DNSmasq configuration to ${DNSMASQ_CONFIG_FILE}..."

cat << EOF | sudo tee "${DNSMASQ_CONFIG_FILE}" > /dev/null
# Listen only on LAN interface
interface=${LAN_INTERFACE}
bind-interfaces

# Listen on all relevant LAN addresses (IPv4 + IPv6 ULA)
listen-address=127.0.0.1,192.168.82.1,fd00:82::1

# Do not read /etc/resolv.conf (use only defined upstreams)
no-resolv

# Upstream resolvers (can be replaced with unbound 127.0.0.1#5353 later)
server=127.0.0.1#5353
server=::1#5353

# Local DNS domain
domain=lan
local=/lan/
expand-hosts

# DHCPv4 configuration
dhcp-range=192.168.82.100,192.168.82.240,12h
dhcp-option=3,192.168.82.1                     # Default gateway
dhcp-option=6,192.168.82.1                     # IPv4 DNS

# IPv6 RA + DHCPv6 configuration
enable-ra
dhcp-range=::100,::1ff,constructor:${LAN_INTERFACE},ra-stateless,ra-names,12h

# Advertise only your local resolver via IPv6 RA (fd00:82::1)
dhcp-option=option6:dns-server,[fd00:82::1]
dhcp-option=option6:domain-search,lan

# Logging
log-dhcp
log-facility=/var/log/dnsmasq.log

# Cache tuning
cache-size=10000
EOF

echo "✅ DNSmasq configuration saved."

# --- Section 4: Deploy RADVD Configuration ---
echo ""
echo "4. Deploying RADVD configuration to ${RADVD_CONFIG_FILE}..."

cat << EOF | sudo tee "${RADVD_CONFIG_FILE}" > /dev/null
# ==========================
# radvd Configuration for Dual Stack Router
# IPv6 Router Advertisement Daemon
# ==========================

interface ${LAN_INTERFACE}
{
    AdvSendAdvert on;
    MaxRtrAdvInterval 30;
    AdvManagedFlag off;          # Stateless (SLAAC) mode
    AdvOtherConfigFlag on;       # DHCPv6 supplies DNS info
    AdvLinkMTU 1500;

    # Automatically use the delegated prefix (from wide-dhcpv6-client)
    prefix ::/64
    {
        AdvOnLink on;
        AdvAutonomous on;
        AdvRouterAddr on;
    };

    # Advertise router’s IPv6 ULA address as the DNS server
    RDNSS fd00:82::1
    {
        AdvRDNSSLifetime 600;
    };

    DNSSL lan
    {
        AdvDNSSLLifetime 600;
    };
};
EOF

echo "✅ RADVD configuration saved."

# --- Section 5: Deploy UNBOUND Configuration and Root Hints ---
echo ""
echo "5. Deploying Unbound configuration and fetching root hints..."

# 5a. Fetch root hints file
echo "Fetching and securing root.hints..."
sudo wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root || echo "⚠️ WGET failed. Ensure it is installed."
sudo chown unbound:unbound /var/lib/unbound/root.hints 2>/dev/null || echo "⚠️ Could not set 'unbound' ownership. Ensure user 'unbound' exists."
sudo chmod 644 /var/lib/unbound/root.hints

# 5b. Deploy Unbound router.conf
sudo mkdir -p /etc/unbound/unbound.conf.d
cat << EOF | sudo tee "${UNBOUND_CONFIG_FILE}" > /dev/null
server:
    verbosity: 1
    interface: 127.0.0.1
    interface: ::1
    port: 5353
    do-ip4: yes
    do-ip6: yes
    do-udp: yes
    do-tcp: yes
    access-control: 127.0.0.0/8 allow
    access-control: ::1 allow
    root-hints: /var/lib/unbound/root.hints
    prefetch: yes
    prefetch-key: yes
    qname-minimisation: yes
    cache-min-ttl: 3600
    cache-max-ttl: 86400
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    val-clean-additional: yes
    rrset-roundrobin: yes
    aggressive-nsec: yes
    minimal-responses: yes
    msg-cache-size: 64m
    rrset-cache-size: 128m
    outgoing-range: 512
    num-queries-per-thread: 4096
    so-reuseport: yes
    edns-buffer-size: 1232
EOF

echo "✅ Unbound configuration saved."

# --- Section 6: Enable Services ---
echo ""
echo "6. Ensuring services are enabled for boot..."

# Enable DHCP6C
if command -v dhcp6c &> /dev/null; then
    sudo systemctl enable wide-dhcpv6-client 2>/dev/null || sudo systemctl enable dhcp6c 2>/dev/null
    echo "✅ wide-dhcpv6-client enabled."
else
    echo "⚠️ dhcp6c command not found. Skipping enable."
fi

# Enable Unbound
if command -v unbound &> /dev/null; then
    sudo systemctl enable unbound
    echo "✅ unbound enabled."
else
    echo "⚠️ unbound not installed. Skipping enable."
fi

# Enable DNSmasq
if command -v dnsmasq &> /dev/null; then
    sudo systemctl enable dnsmasq
    echo "✅ dnsmasq enabled."
else
    echo "⚠️ dnsmasq not installed. Skipping enable."
fi

# Enable RADVD
if command -v radvd &> /dev/null; then
    sudo systemctl enable radvd
    echo "✅ radvd enabled."
else
    echo "⚠️ radvd not installed. Skipping enable."
fi

# --- Section 7: Final Message and Reboot ---
echo ""
echo "=========================================================="
echo "🚨 **Configuration completed, rebooting...**"
echo "➡️ **Please run pppoeconf when the router has completed booting up.**"
echo "=========================================================="
sleep 5
sudo reboot
