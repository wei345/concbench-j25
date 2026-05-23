# Determining the optimal thread count for the thread pool model

## Commands used

```bash
# Stop
docker container kill concbench-j25-thread-pool
# On the app server
# Change server.tomcat.threads.max accordingly
docker run --rm -d \
  --name concbench-j25-thread-pool \
  --ulimit nofile=200000:200000 \
  --memory=12g \
  -e JAVA_OPTS="-XX:+UseZGC \
    -Xmx8G -Xms8G \
    -XX:NativeMemoryTracking=summary \
    -Dserver.tomcat.threads.max=3625" \
  -v `pwd`/logs:/app/logs \
  -p 8080:8080 \
  concbench-j25-thread-pool
sleep 2; cat logs/out.log
tail -f logs/usage-thread-pool.csv


# On the load generator server
wrk -t8 -c10000 -d120s --latency --timeout 10s http://10.152.0.2:8080/benchmark/delay/100 | tee performance.txt
```

## 2000 threads

JVM metrics

```
elapsed_seconds, cpu_percentage, threads, stack_committed_mb, stack_reserved_mb, heap_used_mb, eden_mb, s0_kb, s1_kb, old_mb, meta_mb, compressed_class_mb, ygc, ygct, fgc, fgct, cgc, cgct, gct
119, 181.0, 2030, 246, 2046, 1724.0, 1320, 0.0, 0.0, 404, 32, 4, 12, 0.000, 0, 0.000, 20, 0.000, 0.000
121, 182.2, 2030, 246, 2046, 1724.0, 1320, 0.0, 0.0, 404, 32, 4, 12, 0.000, 0, 0.000, 20, 0.000, 0.000
122, 238.3, 2030, 246, 2046, 2538.0, 2134, 0.0, 0.0, 404, 32, 4, 15, 0.000, 0, 0.000, 20, 0.000, 0.000
124, 179.6, 2030, 246, 2046, 2538.0, 2134, 0.0, 0.0, 404, 32, 4, 15, 0.000, 0, 0.000, 20, 0.000, 0.000
125, 182.1, 2030, 246, 2046, 2538.0, 2134, 0.0, 0.0, 404, 32, 4, 15, 0.000, 0, 0.000, 20, 0.000, 0.000
127, 178.6, 2030, 246, 2046, 2538.0, 2134, 0.0, 0.0, 404, 32, 4, 15, 0.000, 0, 0.000, 20, 0.000, 0.000
128, 176.9, 2030, 246, 2046, 2538.0, 2134, 0.0, 0.0, 404, 32, 4, 15, 0.000, 0, 0.000, 20, 0.000, 0.000
129, 176.7, 2030, 246, 2046, 2538.0, 2134, 0.0, 0.0, 404, 32, 4, 15, 0.000, 0, 0.000, 20, 0.000, 0.000
```

wrk metrics

```
wrk -t8 -c10000 -d120s --latency --timeout 10s http://10.152.0.2:8080/benchmark/delay/100 | tee performance.txt
Running 2m test @ http://10.152.0.2:8080/benchmark/delay/100
  8 threads and 10000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   519.43ms  112.84ms   2.26s    95.96%
    Req/Sec     2.43k   413.30     3.61k    85.57%
  Latency Distribution
     50%  502.63ms
     75%  505.71ms
     90%  508.93ms
     99%    1.04s 
  2314436 requests in 2.00m, 238.74MB read
Requests/sec:  19272.83
Transfer/sec:      1.99MB
```

## 2500 threads

JVM metrics

```
elapsed_seconds, cpu_percentage, threads, stack_committed_mb, stack_reserved_mb, heap_used_mb, eden_mb, s0_kb, s1_kb, old_mb, meta_mb, compressed_class_mb, ygc, ygct, fgc, fgct, cgc, cgct, gct
112, 230.0, 2530, 301, 2551, 2308.0, 1852, 0.0, 0.0, 456, 32, 4, 12, 0.000, 0, 0.000, 25, 0.000, 0.000
114, 231.9, 2530, 301, 2551, 2308.0, 1852, 0.0, 0.0, 456, 32, 4, 12, 0.000, 0, 0.000, 25, 0.000, 0.000
116, 231.3, 2530, 301, 2551, 2308.0, 1852, 0.0, 0.0, 456, 32, 4, 12, 0.000, 0, 0.000, 25, 0.000, 0.000
117, 229.2, 2530, 301, 2551, 2308.0, 1852, 0.0, 0.0, 456, 32, 4, 12, 0.000, 0, 0.000, 25, 0.000, 0.000
119, 229.5, 2530, 301, 2551, 2308.0, 1852, 0.0, 0.0, 456, 32, 4, 12, 0.000, 0, 0.000, 25, 0.000, 0.000
120, 230.8, 2530, 301, 2551, 2308.0, 1852, 0.0, 0.0, 456, 32, 4, 12, 0.000, 0, 0.000, 25, 0.000, 0.000
122, 231.1, 2530, 301, 2551, 2308.0, 1852, 0.0, 0.0, 456, 32, 4, 12, 0.000, 0, 0.000, 25, 0.000, 0.000
```

wrk metrics

```
Running 2m test @ http://10.152.0.2:8080/benchmark/delay/100
  8 threads and 10000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   427.96ms  139.98ms   2.46s    94.20%
    Req/Sec     2.99k   544.50     4.22k    90.17%
  Latency Distribution
     50%  403.12ms
     75%  406.14ms
     90%  410.99ms
     99%    1.16s 
  2846030 requests in 2.00m, 293.49MB read
Requests/sec:  23701.31
Transfer/sec:      2.44MB
```

## 3000 threads

JVM metrics

```
elapsed_seconds, cpu_percentage, threads, stack_committed_mb, stack_reserved_mb, heap_used_mb, eden_mb, s0_kb, s1_kb, old_mb, meta_mb, compressed_class_mb, ygc, ygct, fgc, fgct, cgc, cgct, gct
111, 282.4, 3030, 367, 3055, 1450.0, 872, 0.0, 0.0, 578, 32, 4, 18, 0.000, 0, 0.000, 20, 0.000, 0.001
113, 325.2, 3030, 367, 3055, 1450.0, 872, 0.0, 0.0, 578, 32, 4, 18, 0.000, 0, 0.000, 20, 0.000, 0.001
115, 277.0, 3030, 367, 3055, 1450.0, 872, 0.0, 0.0, 578, 32, 4, 18, 0.000, 0, 0.000, 20, 0.000, 0.001
117, 279.1, 3030, 367, 3055, 1450.0, 872, 0.0, 0.0, 578, 32, 4, 18, 0.000, 0, 0.000, 20, 0.000, 0.001
118, 281.7, 3030, 367, 3055, 1450.0, 872, 0.0, 0.0, 578, 32, 4, 18, 0.000, 0, 0.000, 20, 0.000, 0.001
120, 281.4, 3030, 367, 3055, 1450.0, 872, 0.0, 0.0, 578, 32, 4, 18, 0.000, 0, 0.000, 20, 0.000, 0.001
122, 293.2, 3030, 367, 3055, 2678.0, 2074, 0.0, 0.0, 604, 32, 4, 18, 0.000, 0, 0.000, 23, 0.000, 0.001
```

wrk metrics

```
Running 2m test @ http://10.152.0.2:8080/benchmark/delay/100
  8 threads and 10000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   366.44ms  138.24ms   2.24s    93.22%
    Req/Sec     3.51k   717.33     4.57k    89.70%
  Latency Distribution
     50%  337.45ms
     75%  340.61ms
     90%  372.00ms
     99%    1.06s 
  3341041 requests in 2.00m, 344.66MB read
Requests/sec:  27824.00
Transfer/sec:      2.87MB
```

## 3250 threads

JVM metrics

```
elapsed_seconds, cpu_percentage, threads, stack_committed_mb, stack_reserved_mb, heap_used_mb, eden_mb, s0_kb, s1_kb, old_mb, meta_mb, compressed_class_mb, ygc, ygct, fgc, fgct, cgc, cgct, gct
112, 309.5, 3280, 398, 3307, 1618.0, 728, 0.0, 0.0, 890, 32, 4, 21, 0.000, 0, 0.000, 25, 0.000, 0.001
114, 303.3, 3280, 398, 3307, 6834.0, 5944, 0.0, 0.0, 890, 32, 4, 22, 0.000, 0, 0.000, 25, 0.000, 0.001
116, 358.3, 3280, 398, 3307, 3464.0, 2574, 0.0, 0.0, 890, 32, 4, 24, 0.000, 0, 0.000, 25, 0.000, 0.001
118, 299.6, 3280, 398, 3307, 3464.0, 2574, 0.0, 0.0, 890, 32, 4, 24, 0.000, 0, 0.000, 25, 0.000, 0.001
120, 299.4, 3280, 398, 3307, 3464.0, 2574, 0.0, 0.0, 890, 32, 4, 24, 0.000, 0, 0.000, 25, 0.000, 0.001
122, 301.0, 3280, 398, 3307, 3464.0, 2574, 0.0, 0.0, 890, 32, 4, 24, 0.000, 0, 0.000, 25, 0.000, 0.001
124, 300.9, 3280, 398, 3307, 3464.0, 2574, 0.0, 0.0, 890, 32, 4, 24, 0.000, 0, 0.000, 25, 0.000, 0.001
```

wrk metrics

```
Running 2m test @ http://10.152.0.2:8080/benchmark/delay/100
  8 threads and 10000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   350.18ms  165.62ms   2.56s    93.03%
    Req/Sec     3.72k     0.86k    5.06k    88.39%
  Latency Distribution
     50%  312.16ms
     75%  314.95ms
     90%  389.05ms
     99%    1.16s 
  3546148 requests in 2.00m, 365.79MB read
Requests/sec:  29531.38
Transfer/sec:      3.05MB
```

## 3500 threads

JVM metrics

```
elapsed_seconds, cpu_percentage, threads, stack_committed_mb, stack_reserved_mb, heap_used_mb, eden_mb, s0_kb, s1_kb, old_mb, meta_mb, compressed_class_mb, ygc, ygct, fgc, fgct, cgc, cgct, gct
134, 325.2, 3530, 424, 3560, 2128.0, 1452, 0.0, 0.0, 676, 32, 4, 30, 0.000, 0, 0.000, 25, 0.000, 0.001
136, 326.9, 3530, 424, 3560, 2128.0, 1452, 0.0, 0.0, 676, 32, 4, 30, 0.000, 0, 0.000, 25, 0.000, 0.001
138, 370.2, 3530, 424, 3560, 3584.0, 2810, 0.0, 0.0, 774, 32, 4, 33, 0.001, 0, 0.000, 25, 0.000, 0.001
141, 329.9, 3530, 424, 3560, 3584.0, 2810, 0.0, 0.0, 774, 32, 4, 33, 0.001, 0, 0.000, 25, 0.000, 0.001
143, 328.5, 3530, 424, 3560, 3584.0, 2810, 0.0, 0.0, 774, 32, 4, 33, 0.001, 0, 0.000, 25, 0.000, 0.001
145, 327.8, 3530, 424, 3560, 3584.0, 2810, 0.0, 0.0, 774, 32, 4, 33, 0.001, 0, 0.000, 25, 0.000, 0.001
147, 329.2, 3530, 424, 3560, 3584.0, 2810, 0.0, 0.0, 774, 32, 4, 33, 0.001, 0, 0.000, 25, 0.000, 0.001
```

wrk metrics

```
Running 2m test @ http://10.152.0.2:8080/benchmark/delay/100
  8 threads and 10000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   330.04ms  154.93ms   2.35s    93.54%
    Req/Sec     3.97k     0.92k    5.43k    87.38%
  Latency Distribution
     50%  290.30ms
     75%  296.46ms
     90%  388.07ms
     99%    1.12s 
  3770598 requests in 2.00m, 388.90MB read
Requests/sec:  31402.86
Transfer/sec:      3.24MB
```

## 3625 threads

JVM metrics

```
elapsed_seconds, cpu_percentage, threads, stack_committed_mb, stack_reserved_mb, heap_used_mb, eden_mb, s0_kb, s1_kb, old_mb, meta_mb, compressed_class_mb, ygc, ygct, fgc, fgct, cgc, cgct, gct
110, 346.1, 3655, 444, 3686, 2040.0, 1660, 0.0, 0.0, 380, 32, 4, 24, 0.000, 0, 0.000, 25, 0.000, 0.001
112, 343.0, 3655, 444, 3686, 6008.0, 5616, 0.0, 0.0, 392, 32, 4, 25, 0.000, 0, 0.000, 25, 0.000, 0.001
115, 371.3, 3655, 444, 3686, 4898.0, 4506, 0.0, 0.0, 392, 32, 4, 27, 0.000, 0, 0.000, 25, 0.000, 0.001
117, 348.1, 3655, 444, 3686, 4898.0, 4506, 0.0, 0.0, 392, 32, 4, 27, 0.000, 0, 0.000, 25, 0.000, 0.001
120, 340.4, 3655, 444, 3686, 4898.0, 4506, 0.0, 0.0, 392, 32, 4, 27, 0.000, 0, 0.000, 25, 0.000, 0.001
122, 342.2, 3655, 444, 3686, 4898.0, 4506, 0.0, 0.0, 392, 32, 4, 27, 0.000, 0, 0.000, 25, 0.000, 0.001
124, 340.4, 3655, 444, 3686, 6092.0, 5664, 0.0, 0.0, 428, 32, 4, 28, 0.000, 0, 0.000, 25, 0.000, 0.001
```

wrk metrics

```
Running 2m test @ http://10.152.0.2:8080/benchmark/delay/100
  8 threads and 10000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   327.79ms  177.66ms   2.81s    92.75%
    Req/Sec     4.03k     1.02k    5.24k    85.16%
  Latency Distribution
     50%  280.62ms
     75%  290.03ms
     90%  410.30ms
     99%    1.22s 
  3826142 requests in 2.00m, 394.62MB read
Requests/sec:  31862.72
Transfer/sec:      3.29MB
```

## 3750 threads

JVM metrics

```
elapsed_seconds, cpu_percentage, threads, stack_committed_mb, stack_reserved_mb, heap_used_mb, eden_mb, s0_kb, s1_kb, old_mb, meta_mb, compressed_class_mb, ygc, ygct, fgc, fgct, cgc, cgct, gct
106, 413.3, 3780, 459, 3812, 5086.0, 4712, 0.0, 0.0, 374, 32, 4, 36, 0.001, 0, 0.000, 25, 0.000, 0.001
109, 357.1, 3780, 459, 3812, 5086.0, 4712, 0.0, 0.0, 374, 32, 4, 36, 0.001, 0, 0.000, 25, 0.000, 0.001
112, 375.1, 3780, 459, 3812, 5572.0, 5198, 0.0, 0.0, 374, 32, 4, 37, 0.001, 0, 0.000, 25, 0.000, 0.001
115, 394.7, 3780, 459, 3812, 3394.0, 3020, 0.0, 0.0, 374, 32, 4, 39, 0.001, 0, 0.000, 25, 0.000, 0.001
117, 368.0, 3780, 459, 3812, 3394.0, 3020, 0.0, 0.0, 374, 32, 4, 39, 0.001, 0, 0.000, 25, 0.000, 0.001
120, 365.5, 3780, 459, 3812, 3394.0, 3020, 0.0, 0.0, 374, 32, 4, 39, 0.001, 0, 0.000, 25, 0.000, 0.001
123, 367.1, 3780, 459, 3812, 5894.0, 5520, 0.0, 0.0, 374, 32, 4, 40, 0.001, 0, 0.000, 25, 0.000, 0.001
```

wrk metrics

```
hmark/delay/100 | tee performance.txt
Running 2m test @ http://10.152.0.2:8080/benchmark/delay/100
  8 threads and 10000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   320.68ms  140.06ms   2.08s    91.62%
    Req/Sec     4.03k     1.09k    5.25k    83.68%
  Latency Distribution
     50%  273.02ms
     75%  312.58ms
     90%  420.70ms
     99%  965.84ms
  3838016 requests in 2.00m, 395.85MB read
Requests/sec:  31960.54
Transfer/sec:      3.30MB
```

## 3875 threads

JVM metrics

```
elapsed_seconds, cpu_percentage, threads, stack_committed_mb, stack_reserved_mb, heap_used_mb, eden_mb, s0_kb, s1_kb, old_mb, meta_mb, compressed_class_mb, ygc, ygct, fgc, fgct, cgc, cgct, gct
105, 397.0, 3905, 483, 3938, 4874.0, 4442, 0.0, 0.0, 432, 32, 4, 39, 0.001, 0, 0.000, 20, 0.000, 0.001
108, 374.3, 3905, 483, 3938, 4874.0, 4442, 0.0, 0.0, 432, 32, 4, 39, 0.001, 0, 0.000, 20, 0.000, 0.001
111, 371.2, 3905, 483, 3938, 4874.0, 4442, 0.0, 0.0, 432, 32, 4, 39, 0.001, 0, 0.000, 20, 0.000, 0.001
114, 400.7, 3905, 483, 3938, 4834.0, 4402, 0.0, 0.0, 432, 32, 4, 42, 0.001, 0, 0.000, 20, 0.000, 0.001
116, 375.7, 3905, 483, 3938, 4834.0, 4402, 0.0, 0.0, 432, 32, 4, 42, 0.001, 0, 0.000, 20, 0.000, 0.001
119, 347.0, 3905, 483, 3938, 4834.0, 4402, 0.0, 0.0, 432, 32, 4, 42, 0.001, 0, 0.000, 20, 0.000, 0.001
122, 372.5, 3905, 483, 3938, 5686.0, 5252, 0.0, 0.0, 434, 32, 4, 43, 0.001, 0, 0.000, 20, 0.000, 0.001
```

wrk metrics

```
Running 2m test @ http://10.152.0.2:8080/benchmark/delay/100
  8 threads and 10000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   330.44ms  176.32ms   2.59s    92.44%
    Req/Sec     3.99k     1.22k    5.41k    82.52%
  Latency Distribution
     50%  269.93ms
     75%  327.21ms
     90%  445.83ms
     99%    1.13s 
  3798059 requests in 2.00m, 391.73MB read
Requests/sec:  31633.19
Transfer/sec:      3.26MB
```

## 4000 threads

JVM metrics

```
elapsed_seconds, cpu_percentage, threads, stack_committed_mb, stack_reserved_mb, heap_used_mb, eden_mb, s0_kb, s1_kb, old_mb, meta_mb, compressed_class_mb, ygc, ygct, fgc, fgct, cgc, cgct, gct
106, 378.0, 4030, 486, 4064, 3204.0, 2786, 0.0, 0.0, 418, 32, 4, 46, 0.001, 0, 0.000, 20, 0.000, 0.001
108, 405.4, 4030, 486, 4064, 2514.0, 2098, 0.0, 0.0, 416, 32, 4, 46, 0.001, 0, 0.000, 24, 0.000, 0.001
111, 391.2, 4030, 486, 4064, 2514.0, 2098, 0.0, 0.0, 416, 32, 4, 46, 0.001, 0, 0.000, 24, 0.000, 0.001
114, 382.5, 4030, 486, 4064, 4478.0, 4184, 0.0, 0.0, 294, 32, 4, 49, 0.001, 0, 0.000, 24, 0.000, 0.001
116, 419.4, 4030, 486, 4064, 4478.0, 4184, 0.0, 0.0, 294, 32, 4, 49, 0.001, 0, 0.000, 24, 0.000, 0.001
119, 396.4, 4030, 486, 4064, 5020.0, 4726, 0.0, 0.0, 294, 32, 4, 50, 0.001, 0, 0.000, 24, 0.000, 0.001
121, 423.1, 4030, 486, 4064, 4864.0, 4516, 0.0, 0.0, 348, 32, 4, 52, 0.001, 0, 0.000, 24, 0.000, 0.001
123, 383.9, 4030, 486, 4064, 4864.0, 4516, 0.0, 0.0, 348, 32, 4, 52, 0.001, 0, 0.000, 24, 0.000, 0.001
```

wrk metrics

```
hmark/delay/100 | tee performance.txt
Running 2m test @ http://10.152.0.2:8080/benchmark/delay/100
  8 threads and 10000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   330.10ms  167.79ms   2.38s    92.29%
    Req/Sec     3.97k     1.26k    5.64k    81.02%
  Latency Distribution
     50%  276.92ms
     75%  343.06ms
     90%  444.77ms
     99%    1.17s 
  3776830 requests in 2.00m, 389.55MB read
Requests/sec:  31453.71
Transfer/sec:      3.24MB
```

## 4500 threads

JVM metrics

```
elapsed_seconds, cpu_percentage, threads, stack_committed_mb, stack_reserved_mb, heap_used_mb, eden_mb, s0_kb, s1_kb, old_mb, meta_mb, compressed_class_mb, ygc, ygct, fgc, fgct, cgc, cgct, gct
112, 375.3, 4530, 546, 4568, 5252.0, 4838, 0.0, 0.0, 414, 32, 4, 65, 0.001, 0, 0.000, 24, 0.001, 0.002
115, 419.4, 4530, 546, 4568, 5778.0, 5364, 0.0, 0.0, 414, 32, 4, 67, 0.001, 0, 0.000, 24, 0.001, 0.002
117, 378.7, 4530, 546, 4568, 5778.0, 5364, 0.0, 0.0, 414, 32, 4, 67, 0.001, 0, 0.000, 24, 0.001, 0.002
119, 364.5, 4530, 546, 4568, 5958.0, 5544, 0.0, 0.0, 414, 32, 4, 70, 0.001, 0, 0.000, 24, 0.001, 0.002
122, 370.7, 4530, 546, 4568, 5958.0, 5544, 0.0, 0.0, 414, 32, 4, 70, 0.001, 0, 0.000, 24, 0.001, 0.002
124, 401.1, 4530, 546, 4568, 4592.0, 4178, 0.0, 0.0, 414, 32, 4, 73, 0.001, 0, 0.000, 24, 0.001, 0.002
126, 382.0, 4530, 546, 4568, 4592.0, 4178, 0.0, 0.0, 414, 32, 4, 73, 0.001, 0, 0.000, 24, 0.001, 0.002
```

wrk metrics

```
hmark/delay/100 | tee performance.txt
Running 2m test @ http://10.152.0.2:8080/benchmark/delay/100
  8 threads and 10000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   358.59ms  150.15ms   2.08s    92.28%
    Req/Sec     3.59k     1.24k    5.82k    65.64%
  Latency Distribution
     50%  327.19ms
     75%  383.39ms
     90%  459.50ms
     99%    1.06s 
  3419568 requests in 2.00m, 352.75MB read
Requests/sec:  28477.88
Transfer/sec:      2.94MB
```

## 5000 threads

JVM metrics

```
elapsed_seconds, cpu_percentage, threads, stack_committed_mb, stack_reserved_mb, heap_used_mb, eden_mb, s0_kb, s1_kb, old_mb, meta_mb, compressed_class_mb, ygc, ygct, fgc, fgct, cgc, cgct, gct
116, 419.1, 5030, 607, 5073, 2316.0, 1938, 0.0, 0.0, 378, 32, 4, 51, 0.001, 0, 0.000, 25, 0.000, 0.001
118, 377.6, 5030, 607, 5073, 4566.0, 4270, 0.0, 0.0, 296, 32, 4, 54, 0.001, 0, 0.000, 25, 0.000, 0.001
120, 374.7, 5030, 607, 5073, 4566.0, 4270, 0.0, 0.0, 296, 32, 4, 54, 0.001, 0, 0.000, 25, 0.000, 0.001
123, 385.0, 5030, 607, 5073, 4566.0, 4270, 0.0, 0.0, 296, 32, 4, 54, 0.001, 0, 0.000, 25, 0.000, 0.001
125, 389.6, 5030, 607, 5073, 5472.0, 5172, 0.0, 0.0, 300, 32, 4, 57, 0.001, 0, 0.000, 25, 0.000, 0.001
127, 378.7, 5030, 607, 5073, 5472.0, 5172, 0.0, 0.0, 300, 32, 4, 57, 0.001, 0, 0.000, 25, 0.000, 0.001
130, 453.9, 5030, 607, 5074, 4540.0, 4240, 0.0, 0.0, 300, 32, 4, 60, 0.001, 0, 0.000, 25, 0.000, 0.001
```

wrk metrics

```
Running 2m test @ http://10.152.0.2:8080/benchmark/delay/100
  8 threads and 10000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   370.17ms  162.16ms   2.61s    92.20%
    Req/Sec     3.49k     1.22k    5.71k    65.34%
  Latency Distribution
     50%  335.91ms
     75%  395.77ms
     90%  476.01ms
     99%    1.07s 
  3318515 requests in 2.00m, 342.34MB read
Requests/sec:  27634.50
Transfer/sec:      2.85MB
```

## 10000 threads

JVM metrics

```
elapsed_seconds, cpu_percentage, threads, stack_committed_mb, stack_reserved_mb, heap_used_mb, eden_mb, s0_kb, s1_kb, old_mb, meta_mb, compressed_class_mb, ygc, ygct, fgc, fgct, cgc, cgct, gct
158, 384.8, 10030, 1073, 10117, 6426.0, 5946, 0.0, 0.0, 480, 32, 4, 43, 0.001, 0, 0.000, 24, 0.000, 0.001
161, 397.8, 10030, 1073, 10117, 3254.0, 2774, 0.0, 0.0, 480, 32, 4, 44, 0.001, 0, 0.000, 24, 0.000, 0.001
163, 379.3, 10030, 1073, 10117, 3790.0, 3308, 0.0, 0.0, 482, 32, 4, 46, 0.001, 0, 0.000, 24, 0.000, 0.001
166, 401.4, 10030, 1073, 10117, 3790.0, 3308, 0.0, 0.0, 482, 32, 4, 46, 0.001, 0, 0.000, 24, 0.000, 0.001
168, 382.0, 10030, 1073, 10117, 4624.0, 4140, 0.0, 0.0, 484, 32, 4, 47, 0.001, 0, 0.000, 24, 0.000, 0.001
171, 366.2, 10030, 1073, 10117, 5060.0, 4538, 0.0, 0.0, 522, 32, 4, 49, 0.001, 0, 0.000, 24, 0.000, 0.001
174, 387.8, 10030, 1073, 10117, 5060.0, 4538, 0.0, 0.0, 522, 32, 4, 49, 0.001, 0, 0.000, 24, 0.000, 0.001
```

wrk metrics

```
Running 2m test @ http://10.152.0.2:8080/benchmark/delay/100
  8 threads and 10000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   446.59ms  186.97ms   3.05s    92.91%
    Req/Sec     2.89k     0.97k    5.06k    69.25%
  Latency Distribution
     50%  407.91ms
     75%  474.45ms
     90%  571.23ms
     99%    1.32s 
  2746649 requests in 2.00m, 283.26MB read
Requests/sec:  22871.94
Transfer/sec:      2.36MB
```

