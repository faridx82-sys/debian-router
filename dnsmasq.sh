#!/bin/bash
# dnsmasq.sh: Deploy dnsmasq configuration to /etc/dnsmasq.d/router.conf
# Prompts user for the LAN interface name.

# --- User Input Prompt ---
read -r -p "Enter the **LAN interface name** (e.g., ens18, eth0): " LAN_INTERFACE
# ---

# Define the target configuration file path and name
DNSMASQ_CONFIG_FILE="/etc/dnsmasq.d/router.conf"

echo "Using interface: **${LAN_INTERFACE}**"
echo "Attempting to create dnsmasq configuration file: ${DNSMASQ_CONFIG_FILE}"

# Use a heredoc to write the dnsmasq configuration content to the target file
# The variable ${LAN_INTERFACE} is used in place of 'ens18'
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

echo "**Configuration successfully saved to ${DNSMASQ_CONFIG_FILE}.**"

# Check if dnsmasq is installed and active
if command -v dnsmasq &> /dev/null; then
    echo "Restarting dnsmasq service to load the new configuration..."
    sudo systemctl restart dnsmasq
    if [ $? -eq 0 ]; then
        echo "✅ dnsmasq service restarted successfully."
    else
        echo "❌ Failed to restart dnsmasq. Check logs for details (e.g., journalctl -xe | grep dnsmasq)."
    fi
else
    echo "⚠️ dnsmasq command not found. Please install it (e.g., 'sudo apt install dnsmasq') and then restart the service manually."
fi
