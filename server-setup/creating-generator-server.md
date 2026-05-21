* Machine type: c3-standard-8 (8 vCPUs, 32 GB Memory)
* CPU platform: Intel Sapphire Rapids

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


```shell
sudo apt-get update
sudo apt-get install wrk
```