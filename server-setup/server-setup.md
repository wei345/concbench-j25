# Server setup

Configuration details are listed in the next section, followed by two sections 
of the equivalent server creating code and software installation code for both
the app server and the generator server.

## Configuration

### 1. Compute & Core Architecture
*   **Machine Family (C3-standard-4)**: Specifically chosen to leverage the **Intel Sapphire Rapids** architecture and **Google Titanium** offload engine. This ensures that "noisy neighbor" effects from the hypervisor are minimized, providing a clean environment for carrier-thread analysis.
*   **Provisioning Model (Standard)**: I selected **Standard** over **Spot** to guarantee instance longevity and deterministic performance. This prevents preemption during long-running tests and avoids the variable performance often seen on preemptible hardware.
*   **Compact Placement Policy**: I applied this to ensure the host and generator VMs reside within the same physical rack. This minimizes internal network hops and ensures consistent, low-latency communication between `wrk` load generator and the Spring Boot application.
*   **Sole-Tenancy (Disabled)**: I left the settings blank. This avoids the extreme cost of dedicated physical hardware, as C3's native isolation is sufficient for academic-grade empirical engineering.

### 2. Storage & Operating System
*   **OS Image (Ubuntu 24.04 LTS)**: Selected for its modern kernel support and compatibility with the latest Java 25 features and **gVNIC** drivers.
*   **Boot Disk (20 GB Hyperdisk Balanced)**: Used the default disk size and type to provide stable IOPS for system logs without unnecessary storage overhead.
    *   **Boot Disk Name**: I used names like `concbench-j25-host`, `concbench-j25-generator`.
*   **Deletion Rule**: I enabled "Delete boot disk when instance is deleted" to maintain a clean project environment and control costs once the dissertation data collection is complete.

### 3. Networking & Security
*   **Network Interface (nic0 default)**: I chose a single interface to ensure a simple, predictable packet path through the kernel.
*   **Dynamic Network Interfaces (Disabled)**: Avoided to eliminate extra virtualization layers and management overhead.
*   **External IPv4 Address(Ephemeral)**: Set to **Ephemeral** to have access to the public internet.
*   **IP Stack Type (IPv4 single-stack)**: Ensures the kernel isn't managing dual-stack routing, which keeps the environment highly deterministic.
*   **Network Interface Card (gVNIC)**: This was enabled as a mechanical necessity for C3 performance, ensuring high-throughput and low-latency internal networking.
*   **Firewall Rules (Unchecked)**: All boxes (HTTP/HTTPS/LB) were left unchecked to keep the instance isolated and focused entirely on internal VPC traffic.
*   **Network Tags**: I used tags like `concbench-j25-host`, `concbench-j25-generator`.
*   **Shielded VM (vTPM & Integrity Monitoring)**: These were enabled to maintain professional security standards. They have near-zero impact on JVM performance while ensuring the boot chain remains untampered.
*   **Secure Boot (Disabled)**: This was unchecked to prevent any unexpected blocking of experimental diagnostic tools or custom kernel parameters during boot.

### 4. Management & Observability
*   **Ops Agent (Unchecked/Disabled)**: I chose not to install the cloud agent. This eliminates the background CPU/Memory overhead of the agent itself, leaving all resources for the Java process.
*   **Startup Script (Automation)**: I utilized the automation box to run the content of tune-app-server.sh or tune-generator-server.sh.
*   **Display Device (Disabled)**: This was left unchecked to avoid unnecessary resource allocation for a virtual frame buffer.
*   **CMEK Revocation Policy (Do nothing)**: This was left as "Do nothing" because Google-managed encryption keys were used, avoiding any accidental benchmark interruptions.
*   **Hostname (Default)**: This was left blank to use the standard GCP internal FQDN, keeping my configuration lean and reducing human-level dependency.

## Creating the app server

Steps:

1. Create a instance of c3-standard-4 (4 vCPUs, 16 GB Memory)
    * You can manually appy the [configuration](#configuration) or 
    * Use the equivalent code below (you need to replace `[YOUR_PROJECT_ID]` and `[YOUR_PROJECT_NUMBER]`)
2. [Install Docker](#Install-Docker)

### Equivalent code

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

### Install Docker

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

## Creating the generator server

Steps:

1. Create a instance of c3-standard-4 (8 vCPUs, 16 GB Memory)
    * You can manually appy the [configuration](#configuration) or 
    * Use the equivalent code below (you need to replace `[YOUR_PROJECT_ID]` and `[YOUR_PROJECT_NUMBER]`)
2. [Install wrk](#Install-wrk)

### Equivalent code 

```
POST https://compute.googleapis.com/compute/v1/projects/[YOUR_PROJECT_ID]/zones/australia-southeast1-a/instances
{
  "canIpForward": false,
  "confidentialInstanceConfig": {
    "enableConfidentialCompute": false
  },
  "deletionProtection": false,
  "description": "Java 25 Concurrency Benchmark Generator",
  "disks": [
    {
      "autoDelete": true,
      "boot": true,
      "deviceName": "concbench-j25-generator",
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
  "machineType": "projects/[YOUR_PROJECT_ID]/zones/australia-southeast1-a/machineTypes/c3-standard-8",
  "metadata": {
    "items": [
      {
        "key": "startup-script",
        "value": "#!/bin/bash\n\nif [ \"$EUID\" -ne 0 ]; then\n  echo \"Please run as root\"\n  exit\nfi\n\necho \"--- Tuning GENERATOR SERVER (wrk) ---\"\n\n# 1. Expand Ephemeral Ports\n# This allows ~64k connections to a single IP:Port\nsysctl -w net.ipv4.ip_local_port_range=\"1024 65535\"\n\n# 2. Fast Socket Recycling\n# When wrk finishes a test, it leaves thousands of sockets in TIME_WAIT.\n# tw_reuse allows the next test to start immediately.\nsysctl -w net.ipv4.tcp_tw_reuse=1\nsysctl -w net.ipv4.tcp_fin_timeout=15\n\n# 3. Increase File Descriptors\nsysctl -w fs.file-max=250000\n\n# 4. Persistent Settings\ncat <<EOF > /etc/sysctl.d/99-generator-benchmark.conf\nnet.ipv4.ip_local_port_range = 1024 65535\nnet.ipv4.tcp_tw_reuse = 1\nnet.ipv4.tcp_fin_timeout = 15\nfs.file-max = 250000\nEOF\n\n# 5. User limits\ncat <<EOF > /etc/security/limits.d/99-benchmark.conf\n* soft nofile 200000\n* hard nofile 200000\nroot soft nofile 200000\nroot hard nofile 200000\nEOF\n\necho \"--- Generator Tuning Complete ---\""
      }
    ]
  },
  "name": "concbench-j25-generator",
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

### Install wrk

```shell
sudo apt-get update
sudo apt-get install wrk
```

