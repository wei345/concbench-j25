# Java 25 concurrency benchmark

This project benchmarks various Java 25 concurrency models for HTTP APIs. It 
evaluates **throughput**, **latency**, and **resource efficiency** (CPU/RAM) 
across three distinct paradigms:

* **Thread pool:** Traditional I/O using a fixed-size executor.
* **Virtual threads:** Lightweight, JVM-managed threads (Project Loom).
* **Reactive streams:** Non-blocking streams using Project Reactor.

## Benchmark deployment topology

```
+--------------------------------------------------------------+
|  HOST SERVER (4 vCPU, 16GB RAM)                              |
|  (Tuned with tune-host.sh)                                   |
|                                                              |
|  +--------------------------------------------------------+  |
|  |  DOCKER CONTAINER (--memory=12g)                       |  |
|  |                                                        |  |
|  |  +--------------------------------------------------+  |  |
|  |  |  UBUNTU 24.04 LTS (Guest OS)                     |  |  |
|  |  |                                                  |  |  |
|  |  |  +--------------------------------------------+  |  |  |
|  |  |  |  SPRING BOOT APP (Java 25, ZGC)            |  |  |  |
|  |  |  |  (Heap: -Xms8G -Xmx8G)                     |  |  |  |
|  |  |  |                                            |  |  |  |
|  |  |  |  - Thread Pool Module /                    |  |  |  |
|  |  |  |  - Virtual Thread Module /                 |  |  |  |
|  |  |  |  - Reactive Module                         |  |  |  |
|  |  |  +--------------------------------------------+  |  |  |
|  |  +--------------------------------------------------+  |  |
|  +--------------------------------------------------------+  |
+--------------------------------------------------------------+
           ^
           |
           |  NETWORK (1 Gbps Virtual Link)
           |  (Low Latency / High PPS)
           |
           v
+--------------------------------------------------------------+
|  GENERATOR SERVER (8 vCPU, 16GB RAM)                         |
|  (Tuned with tune-generator.sh)                              |
|                                                              |
|  +--------------------------------------------------------+  |
|  |  wrk LOAD TESTING TOOL                                 |  |
|  |  (-t8 -c10000 -d600s)                                  |  |
|  +--------------------------------------------------------+  |
+--------------------------------------------------------------+
```

## Pressure tests

Process:

1. Build Docker images
2. Run Docker images
3. Execute pressure tests

### 1. Build Docker images

The server configuration I used is shown below. You can use a different setup 
as long as Docker is installed.

* vCPUs: 4
* Memory: 16GB
* Network: 1 Gbps
* OS: Ubuntu 24.04 LTS tuned with the `tune-host.sh` (in the same directory as this file).

Build Docker images:

```shell
docker build --build-arg APP=thread-pool -t concbench-j25-thread-pool .
docker build --build-arg APP=virtual-thread -t concbench-j25-virtual-thread .
docker build --build-arg APP=reactive -t concbench-j25-reactive .
```

If you want to see what is inside the images,

```shell
# Enter a Docker image, e.g.
docker run --rm -it --entrypoint /bin/bash concbench-j25-thread-pool

# Enter a running Docker container, e.g.
docker exec -it concbench-j25-thread-pool /bin/bash
```

### 2. Run Docker images

Run one of the three images using the `docker run` commands provided below, 
then go down to the "Execute pressure tests" section. You may need to 
adjust the **memory size** based on the available resources on your computer.

```shell
# Start thread-pool
docker run --rm -d \
  --name concbench-j25-thread-pool \
  --ulimit nofile=200000:200000 \
  --memory=12g \
  -e JAVA_OPTS="-XX:+UseZGC \
    -Xmx8G -Xms8G \
    -XX:NativeMemoryTracking=summary \
    -Dserver.tomcat.threads.max=2000" \
  -v `pwd`/logs:/app/logs \
  -p 8080:8080 \
  concbench-j25-thread-pool
cat logs/out.log; sleep 1
tail -f logs/usage-thread-pool.csv
# Stop
docker container kill concbench-j25-thread-pool


# Start virtual-thread
docker run --rm -d \
  --name concbench-j25-virtual-thread \
  --ulimit nofile=200000:200000 \
  --memory=12g \
  -e JAVA_OPTS="-XX:+UseZGC \
    -Xmx8G -Xms8G \
    -XX:NativeMemoryTracking=summary" \
  -v `pwd`/logs:/app/logs \
  -p 8080:8080 \
  concbench-j25-virtual-thread
cat logs/out.log; sleep 1
tail -f logs/usage-virtual-threadd.csv
# Stop
docker container kill concbench-j25-virtual-thread


# Start reactive
docker run --rm -d \
  --name concbench-j25-reactive \
  --ulimit nofile=200000:200000 \
  --memory=12g \
  -e JAVA_OPTS="-XX:+UseZGC \
    -Xmx8G -Xms8G \
    -XX:NativeMemoryTracking=summary" \
  -v `pwd`/logs:/app/logs \
  -p 8080:8080 \
  concbench-j25-reactive
cat logs/out.log; sleep 1
tail -f logs/usage-reactive.csv
# Stop
docker container kill concbench-j25-reactive
```

### 3. Execute pressure tests

The server configuration I used is shown below. You can use a different setup.

Generator server:

* vCPUs: 8
* Memory: 16GB
* Network: 1Gbps
* OS: Ubuntu 24.04 LTS tuned with the `tune-generator.sh` (in the same directory as this file).

The following commands use [wrk](https://github.com/wg/wrk) to perform HTTP 
load tests. You may need to adjust **threads** and **connections** based on the 
available resources on your computer. You can also use other load testing tools.

```shell
# Warm-up: 4 threads, 200 connections, 2 minutes
wrk -t4 -c200 -d120s --latency --timeout 5s http://localhost:8080/benchmark/delay/1000

# Pressure: 8 threads, 10k connections, 10 minutes
wrk -t8 -c10000 -d600s --latency --timeout 15s http://localhost:8080/benchmark/delay/1000
# Server delay: 2s
wrk -t8 -c10000 -d600s --latency --timeout 15s http://localhost:8080/benchmark/delay/2000
# Server delay: 5s
wrk -t8 -c10000 -d600s --latency --timeout 15s http://localhost:8080/benchmark/delay/5000
# Server delay: 10s
wrk -t8 -c10000 -d600s --latency --timeout 15s http://localhost:8080/benchmark/delay/10000
```

## Local execution

You can build and run the three modules (implementations) locally using Maven 
commands or whatever Java IDE you like.

### Prerequisites

* Java 25+
* Maven 3.9+

### Build

```shell
# Compile and package all the three modules
mvn clean package
```

### Run

Run (one of them at a time):

```shell
mvn spring-boot:run -am -pl reactive
mvn spring-boot:run -am -pl thread-pool
mvn spring-boot:run -am -pl virtual-thread
```
