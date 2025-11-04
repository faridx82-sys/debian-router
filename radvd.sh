#!/bin/bash
# radvd.sh: Deploy radvd configuration to /etc/radvd.conf
# Prompts user for the LAN interface name.

# --- User Input Prompt ---
read -r -p "Enter the **LAN interface name** for radvd (e.g., ens18, eth0): " LAN_INTERFACE
# ---

# Define the target configuration file path and name
RADVD_CONFIG_FILE="/etc/radvd.conf"

echo "Using interface: **${LAN_INTERFACE}**"
echo "Attempting to create radvd configuration file: ${RADVD_CONFIG_FILE}"

# Use a heredoc to write the radvd configuration content to the target file
# The variable ${LAN_INTERFACE} is used in place of 'ens18'
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

echo "**Configuration successfully saved to ${RADVD_CONFIG_FILE}.**"

# Check if radvd is installed and active
if command -v radvd &> /dev/null; then
    echo "Restarting radvd service to load the new configuration..."
    sudo systemctl restart radvd
    if [ $? -eq 0 ]; then
        echo "✅ radvd service restarted successfully."
    else
        echo "❌ Failed to restart radvd. Check logs for details (e.g., journalctl -xe | grep radvd)."
    fi
else
    echo "⚠️ radvd command not found. Please install it (e.g., 'sudo apt install radvd') and then restart the service manually."
fi
