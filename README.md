# Java 25 concurrency benchmark

This project benchmarks various Java 25 concurrency models for HTTP APIs. It evaluates **throughput**, **latency**, and **resource efficiency** (CPU/RAM) across three distinct paradigms:

* **Thread Pool:** Traditional I/O using a fixed-size executor.
* **Virtual Threads:** Lightweight, user-mode threads (Project Loom).
* **Reactive:** Non-blocking streams using Project Reactor.

## Project structure

This is a multi-module Maven project:

* `thread-pool`: Benchmark implementation using a fixed thread pool.
* `virtual-thread`: Benchmark implementation using Java virtual threads.
* `reactive`: Benchmark implementation using reactive streams.

## Run the load test

Process:

1. Build the Docker images
2. Run the Docker images
3. Execute load test

### Build the Docker images

The server I used is shown below. You can use different servers, as long as
you have Docker installed. You may need to adjust memory size and number of 
threads to match the size of the available memory on you computer.

* AWS Instance Type: t3.medium or m5.large
* vCPUs: 2
* Memory: 8GB
* Network: Up to 5 Gbps
* OS: Ubuntu 24.04 LTS tuned with the `tune-host.sh`, which is in the same directory as this file.

To build the Docker images,

```shell
# In the root dir, where this file is located 
docker build --build-arg APP=thread-pool -t concbench-j25-thread-pool .
docker build --build-arg APP=virtual-thread -t concbench-j25-virtual-thread .
docker build --build-arg APP=reactive -t concbench-j25-reactive .
```

### Run the Docker images

To run the Docker images built from the previous step 
(we only run one of them at a time),

//    -XX:StartFlightRecording=filename=/logs/thread-pool.jfr,settings=profile,dumponexit=true" \

```shell
# thread-pool
docker run --rm -d \
  --name concbench-j25-thread-pool \
  --ulimit nofile=200000:200000 \
  --memory=6g \
  -e JAVA_OPTS="-XX:+UseZGC \
    -Xmx4G \
    -Xms4G \
    -XX:NativeMemoryTracking=summary \
    -Djdk.tracePinnedThreads=full \
    -Dserver.tomcat.threads.max=2000" \
  -v `pwd`/logs:/logs \
  -p 8080:8080 \
  concbench-j25-thread-pool

# virtual-thread
docker run --rm -d \
  --name concbench-j25-virtual-thread \
  --ulimit nofile=200000:200000 \
  --memory=6g \
  -e JAVA_OPTS="-XX:+UseZGC \
    -Xmx4G \
    -Xms4G \
    -XX:NativeMemoryTracking=summary \
    -Djdk.tracePinnedThreads=full \
    -Dspring.threads.virtual.enabled=true \
    -Dserver.tomcat.threads.max=200000" \
  -v `pwd`/logs:/logs \
  -p 8080:8080 \
  concbench-j25-virtual-thread
  
# reactive
docker run --rm -d \
  --name concbench-j25-reactive \
  --ulimit nofile=200000:200000 \
  --memory=6g \
  -e JAVA_OPTS="-XX:+UseZGC \
    -Xmx4G \
    -Xms4G \
    -XX:NativeMemoryTracking=summary \
    -Dserver.netty.connection-timeout=2s" \
  -v `pwd`/logs:/logs \
  -p 8080:8080 \
  concbench-j25-reactive
```

* `-XX:+UseZGC`: For low-latency/high-thread benchmarks to avoid GC noise
* `-Djdk.tracePinnedThreads`: To capture pinning data for RQ3
* `-XX:NativeMemoryTracking=summary`: Enable tracking thread stack usage via 
the `jcmd`. This will cause 5-10% performance overhead.

You may want to check configuration

```shell
# Check the host limit
ulimit -n

# Check the specific Java process limit inside the container
docker exec concbench-j25-thread-pool cat /proc/self/limits | grep "Max open files"
docker exec concbench-j25-virtual-thread cat /proc/self/limits | grep "Max open files"
docker exec concbench-j25-reactive cat /proc/self/limits | grep "Max open files"

# JVM command-line arguments
docker exec concbench-j25-thread-pool sh -c 'jcmd $(pgrep java) VM.command_line'
docker exec concbench-j25-virtual-thread sh -c 'jcmd $(pgrep java) VM.command_line'
docker exec concbench-j25-reactive sh -c 'jcmd $(pgrep java) VM.command_line'

# Enter a running container
docker exec -it concbench-j25-thread-pool /bin/bash
# Enter a Docker image
docker run --rm -it --entrypoint /bin/bash concbench-j25-thread-pool
```

To stop,

```shell
docker container kill concbench-j25-thread-pool
docker container kill concbench-j25-virtual-thread
docker container kill concbench-j25-reactive
```

### Collect JVM CPU and memory usage

```shell
# Appends CPU and memory usage to a log file every second
# The -it flag allows your terminal to send the interrupt signal (SIGINT) 
# to the shell running inside the container, so that it stops when you press 
docker exec -it concbench-j25-thread-pool sh /app/usage.sh
docker exec -it concbench-j25-virtual-thread sh /app/usage.sh
docker exec -it concbench-j25-reactive sh /app/usage.sh
```

### Execute load test

Use a load testing tool such as [wrk](https://github.com/wg/wrk).

```shell
# 12 threads, 400 total HTTP connections, duration of 10s
wrk -t12 -c400 -d10s --latency http://localhost:8080/benchmark/delay/1000
```

## Development

### Prerequisites

* **Java 25+**
* **Maven 3.9+**
* **Docker**

### Build

```shell
# Compile and package all the three modules
mvn clean package
```

### Run

To run (one of them at a time) using Maven:

```shell
mvn spring-boot:run -am -pl reactive

mvn spring-boot:run -am -pl thread-pool

mvn spring-boot:run -am -pl virtual-thread
```

You can also build this project and run start classes such as 
ReactiveApplication in whatever Java IDE you like.
