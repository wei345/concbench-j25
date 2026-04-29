#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit
fi

echo "--- Starting Kernel Tuning for High Concurrency Benchmark ---"

# 1. Increase File Descriptor Limits
# Necessary for 100k+ concurrent TCP sockets
echo "Configuring File Descriptors..."
sysctl -w fs.file-max=250000

# 2. Expand Ephemeral Port Range
# Prevents 'Address already in use' errors when load testing
echo "Expanding Ephemeral Port Range..."
sysctl -w net.ipv4.ip_local_port_range="1024 65535"

# 3. Increase Connection Tracking (Conntrack)
# Prevents the firewall/kernel from dropping packets at high volume
echo "Increasing Conntrack limits..."
sysctl -w net.netfilter.nf_conntrack_max=250000

# 4. Optimize Network Buffer Memory
# Ensures the 4GB RAM is used efficiently for socket buffers
echo "Optimizing Network Buffers..."
sysctl -w net.core.somaxconn=65535
sysctl -w net.ipv4.tcp_max_syn_backlog=65535
sysctl -w net.core.netdev_max_backlog=65535

# 5. Persistent Settings (survives reboot)
echo "Making settings persistent in /etc/sysctl.d/99-benchmark.conf..."
cat <<EOF > /etc/sysctl.d/99-benchmark.conf
fs.file-max = 250000
net.ipv4.ip_local_port_range = 1024 65535
net.netfilter.nf_conntrack_max = 250000
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 65535
EOF

# 6. Update Security Limits for the current user
echo "Updating /etc/security/limits.conf..."
cat <<EOF >> /etc/security/limits.conf
* soft nofile 200000
* hard nofile 200000
root soft nofile 200000
root hard nofile 200000
EOF

echo "--- Tuning Complete ---"
echo "Note: You may need to log out and back in for 'ulimit -n' changes to take effect."