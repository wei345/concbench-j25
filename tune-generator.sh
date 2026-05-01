#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

echo "--- Tuning GENERATOR SERVER (wrk) ---"

# 1. Expand Ephemeral Ports
# This allows ~64k connections to a single IP:Port
sysctl -w net.ipv4.ip_local_port_range="1024 65535"

# 2. Fast Socket Recycling
# When wrk finishes a test, it leaves thousands of sockets in TIME_WAIT.
# tw_reuse allows the next test to start immediately.
sysctl -w net.ipv4.tcp_tw_reuse=1
sysctl -w net.ipv4.tcp_fin_timeout=15

# 3. Increase File Descriptors
sysctl -w fs.file-max=250000

# 4. Persistent Settings
cat <<EOF > /etc/sysctl.d/99-generator-benchmark.conf
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
fs.file-max = 250000
EOF

# 5. User limits
cat <<EOF > /etc/security/limits.d/99-benchmark.conf
* soft nofile 200000
* hard nofile 200000
root soft nofile 200000
root hard nofile 200000
EOF

echo "--- Generator Tuning Complete ---"