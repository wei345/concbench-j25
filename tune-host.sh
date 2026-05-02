#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

echo "--- Tuning APP HOST (Spring Boot Server) ---"

# 1. File Descriptors (150k is safe for a 100k test)
sysctl -w fs.file-max=250000

# 2. Connection Backlog (Essential for bursty starts)
sysctl -w net.core.somaxconn=65535
sysctl -w net.ipv4.tcp_max_syn_backlog=65535
sysctl -w net.core.netdev_max_backlog=65535

# 3. TCP Memory Pressure Safeguards (CRITICAL for 16GB RAM)
# We force the kernel to keep socket buffers small (4KB-16KB)
# This prevents the kernel from eating all 16GB and starving the JVM Heap
echo "Setting TCP buffer floors to protect JVM Heap..."
sysctl -w net.ipv4.tcp_rmem="4096 8192 16384"
sysctl -w net.ipv4.tcp_wmem="4096 8192 16384"

# 4. Allow rapid recycling of sockets
sysctl -w net.ipv4.tcp_tw_reuse=1

# 5. Persistent Settings
cat <<EOF > /etc/sysctl.d/99-app-benchmark.conf
fs.file-max = 250000
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_rmem = 4096 8192 16384
net.ipv4.tcp_wmem = 4096 8192 16384
net.ipv4.tcp_tw_reuse = 1
EOF

# 6. User limits
cat <<EOF > /etc/security/limits.d/99-benchmark.conf
* soft nofile 200000
* hard nofile 200000
root soft nofile 200000
root hard nofile 200000
EOF

# Check the host limit
# ulimit -n
echo "--- App Host Tuning Complete ---"