* Machine type: c3-standard-4 (4 vCPUs, 16 GB Memory)
* CPU platform: Intel Sapphire Rapids

```
POST https://compute.googleapis.com/compute/v1/projects/[YOUR_PROJECT_ID]/zones/australia-southeast1-a/instances
{
  "canIpForward": false,
  "confidentialInstanceConfig": {
    "enableConfidentialCompute": false
  },
  "deletionProtection": false,
  "description": "Java 25 Concurrency Benchmark Host",
  "disks": [
    {
      "autoDelete": true,
      "boot": true,
      "deviceName": "concbench-j25-host",
      "diskEncryptionKey": {},
      "initializeParams": {
        "diskSizeGb": "20",
        "diskType": "projects/[YOUR_PROJECT_ID]/zones/australia-southeast1-a/diskTypes/hyperdisk-balanced",
        "labels": {},
        "provisionedIops": "3000",
        "provisionedThroughput": "140",
        "sourceImage": "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2404-noble-amd64-v20260429"
      },
      "mode": "READ_WRITE",
      "type": "PERSISTENT"
    }
  ],
  "displayDevice": {
    "enableDisplay": false
  },
  "guestAccelerators": [],
  "instanceEncryptionKey": {},
  "keyRevocationActionType": "NONE",
  "labels": {
    "goog-ec-src": "vm_add-rest"
  },
  "machineType": "projects/[YOUR_PROJECT_ID]/zones/australia-southeast1-a/machineTypes/c3-standard-4",
  "metadata": {
    "items": [
      {
        "key": "startup-script",
        "value": "#!/bin/bash\n\nif [ \"$EUID\" -ne 0 ]; then\n  echo \"Please run as root\"\n  exit\nfi\n\necho \"--- Tuning APP HOST (Spring Boot Server) ---\"\n\n# 1. File Descriptors (150k is safe for a 100k test)\nsysctl -w fs.file-max=250000\n\n# 2. Connection Backlog (Essential for bursty starts)\nsysctl -w net.core.somaxconn=65535\nsysctl -w net.ipv4.tcp_max_syn_backlog=65535\nsysctl -w net.core.netdev_max_backlog=65535\n\n# 3. TCP Memory Pressure Safeguards (CRITICAL for 16GB RAM)\n# We force the kernel to keep socket buffers small (4KB-16KB)\n# This prevents the kernel from eating all 16GB and starving the JVM Heap\necho \"Setting TCP buffer floors to protect JVM Heap...\"\nsysctl -w net.ipv4.tcp_rmem=\"4096 8192 16384\"\nsysctl -w net.ipv4.tcp_wmem=\"4096 8192 16384\"\n\n# 4. Allow rapid recycling of sockets\nsysctl -w net.ipv4.tcp_tw_reuse=1\n\n# 5. Persistent Settings\ncat <<EOF > /etc/sysctl.d/99-app-benchmark.conf\nfs.file-max = 250000\nnet.core.somaxconn = 65535\nnet.ipv4.tcp_max_syn_backlog = 65535\nnet.core.netdev_max_backlog = 65535\nnet.ipv4.tcp_rmem = 4096 8192 16384\nnet.ipv4.tcp_wmem = 4096 8192 16384\nnet.ipv4.tcp_tw_reuse = 1\nEOF\n\n# 6. User limits\ncat <<EOF > /etc/security/limits.d/99-benchmark.conf\n* soft nofile 200000\n* hard nofile 200000\nroot soft nofile 200000\nroot hard nofile 200000\nEOF\n\n# Check the host limit\n# ulimit -n\necho \"--- App Host Tuning Complete ---\""
      }
    ]
  },
  "name": "concbench-j25-host",
  "networkInterfaces": [
    {
      "nicType": "GVNIC",
      "stackType": "IPV4_ONLY",
      "subnetwork": "projects/[YOUR_PROJECT_ID]/regions/australia-southeast1/subnetworks/default"
    }
  ],
  "params": {
    "resourceManagerTags": {}
  },
  "reservationAffinity": {
    "consumeReservationType": "ANY_RESERVATION"
  },
  "scheduling": {
    "automaticRestart": true,
    "onHostMaintenance": "MIGRATE",
    "provisioningModel": "STANDARD"
  },
  "serviceAccounts": [
    {
      "email": "[YOUR_PROJECT_NUMBER]-compute@developer.gserviceaccount.com",
      "scopes": [
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring.write",
        "https://www.googleapis.com/auth/service.management.readonly",
        "https://www.googleapis.com/auth/servicecontrol",
        "https://www.googleapis.com/auth/trace.append"
      ]
    }
  ],
  "shieldedInstanceConfig": {
    "enableIntegrityMonitoring": true,
    "enableSecureBoot": false,
    "enableVtpm": true
  },
  "tags": {
    "items": [
      "concbench-j25"
    ]
  },
  "zone": "projects/[YOUR_PROJECT_ID]/zones/australia-southeast1-a"
}
```

```shell
###################
# Install Docker
###################
# Add Docker’s official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin

# Git is automatically installed as a "recommendation" of docker.

# Check the host limit
ulimit -n
```



