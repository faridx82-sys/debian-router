#!/bin/bash
# Create Crontab Script - step 4:
# Adds reboot cron jobs, creates firewall rule files, with user-input LAN/WAN interfaces

set -e

echo "======================================="
echo " Create Crontab Script"
echo "======================================="

# --- Ask for network interfaces ---
read -rp "Enter LAN interface name [default: ens18]: " LAN_IF
LAN_IF=${LAN_IF:-ens18}

read -rp "Enter WAN interface name [default: ppp0]: " WAN_IF
WAN_IF=${WAN_IF:-ppp0}

echo "[*] Using LAN: $LAN_IF | WAN: $WAN_IF"

# --- Add cron jobs ---
echo "[*] Adding @reboot cron jobs..."

CRON_JOBS=$(cat <<EOF
@reboot /sbin/iptables-restore < /root/rules.fw && echo "OK" >> /var/log/iptables-restore.log 2>&1 || echo "FAILED" >> /var/log/iptables-restore.log 2>&1
@reboot /sbin/ip6tables-restore < /root/rules6.fw && echo "OK" >> /var/log/iptables-restore.log 2>&1 || echo "FAILED" >> /var/log/iptables-restore.log 2>&1
@reboot sleep 600 && systemctl restart dhcpcd.service
EOF
)

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

crontab -l 2>/dev/null > /root/.current_cron || true

while IFS= read -r line; do
  if ! crontab -l 2>/dev/null | grep -Fxq "$line"; then
    (crontab -l 2>/dev/null; echo "$line") | crontab -
  fi
done <<< "$CRON_JOBS"

echo "[+] Cron jobs added successfully."

# --- Create IPv4 rules file ---
echo "[*] Creating /root/rules.fw..."

cat <<EOF > /root/rules.fw
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

# Allow loopback
-A INPUT -i lo -j ACCEPT

# Allow established/related
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow LAN access to router
-A INPUT -i $LAN_IF -j ACCEPT

# Allow SSH (important!)
-A INPUT -p tcp --dport 22 -j ACCEPT

# Allow LAN -> WAN forwarding
-A FORWARD -i $LAN_IF -o $WAN_IF -j ACCEPT

COMMIT

*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]

# NAT: LAN -> WAN
-A POSTROUTING -o $WAN_IF -j MASQUERADE

COMMIT
EOF

chmod 600 /root/rules.fw
echo "[+] /root/rules.fw created successfully."

# --- Create IPv6 rules file ---
echo "[*] Creating /root/rules6.fw..."

cat <<EOF > /root/rules6.fw
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

# Allow loopback
-A INPUT -i lo -j ACCEPT

# Allow established/related traffic
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow ICMPv6 (very important for IPv6 functionality)
-A INPUT -p ipv6-icmp -j ACCEPT
-A FORWARD -p ipv6-icmp -j ACCEPT

# Allow LAN access to router (local management, DHCPv6, etc.)
-A INPUT -i $LAN_IF -j ACCEPT

# Allow DHCPv6 client traffic from WAN (for prefix delegation)
-A INPUT -i $WAN_IF -p udp --dport 546 -j ACCEPT
-A OUTPUT -o $WAN_IF -p udp --dport 547 -j ACCEPT

# Allow SSH (important!)
-A INPUT -p tcp --dport 22 -j ACCEPT

# Allow LAN -> WAN forwarding (IPv6 routing)
-A FORWARD -i $LAN_IF -o $WAN_IF -j ACCEPT

COMMIT
EOF

chmod 600 /root/rules6.fw
echo "[+] /root/rules6.fw created successfully."

echo "======================================="
echo "Create Crontab Script completed!"
echo "LAN: $LAN_IF | WAN: $WAN_IF"
echo "Firewall rules saved to /root/rules.fw and /root/rules6.fw"
echo "======================================="
