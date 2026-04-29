# Java 25 concurrency benchmark

This project is the implementation code for the comparative benchmark of Java 25 concurrency models for HTTP APIs, evaluating throughput and resource efficiency across thread pool, virtual threads, and reactive streams.

This is a multi-module Maven project, there are three modules:

* thread-pool: Benchmark implementation using a fixed thread pool
* virtual-thread: Benchmark implementation using Java virtual threads
* reactive: Benchmark implementation using reactive streams

## Build & run locally 

### Environment requirements

* Java: Compile/run this project.
* Maven: Compile/run this project.
* Docker: Compile/run this project in isolated environments.

### Build

```shell
# Compile and package all the three modules
mvn clean package

# Build Docker image of the "thread-pool" module
docker build -t concbench-threadpool -f Dockerfile-threadpool .

# Build Docker image of the "virtual-thread" module
docker build -t concbench-virtualthread -f Dockerfile-virtualthread .

# Build Docker image of the "reactive" module
docker build -t concbench-reactive -f Dockerfile-reactive .
```

### Run locally

```shell
# Run the image of the "thread-pool" module
docker run -p 8080:8081 --rm concbench-threadpool

# Run the image of the "virtual-thread" module
docker run -p 8080:8082 --rm concbench-virtualthread

# Run the image of the "reactive" module
docker run -p 8080:8083 --rm concbench-reactive
```
## Deployment

* Instance Type: t3.medium or m5.large on AWS
* vCPUs: 2
* Memory: 8GB
* Network: Up to 5 Gbps
* OS: Ubuntu 24.04 LTS tuned with the tune-host.sh in this directory.

Docker run commands (We only run one of them at a time):

```shell
# For the "thread-pool" module
docker run -d \
  --name concbench-threadpool \
  --ulimit nofile=200000:200000 \
  -p 8080:8080 \
  concbench-threadpool

# For the "virtual-thread" module
docker run -d \
  --name concbench-virtualthread \
  --ulimit nofile=200000:200000 \
  -p 8080:8080 \
  concbench-virtualthread
  
# For the "reactive" module
docker run -d \
  --name concbench-reactive \
  --ulimit nofile=200000:200000 \
  -p 8081:8080 \
  concbench-reactive
```

Check configuration

```shell
# Check the host limit
ulimit -n

# Check the specific Java process limit inside the container
docker exec <container_id> cat /proc/self/limits | grep "Max open files"
```
