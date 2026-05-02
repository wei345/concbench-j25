#!/bin/bash
set -e

PID=$(pgrep java)
LOG_FILE="$LOG_DIR/usage-$APP.csv"
# All gc time are reported in seconds.
echo "elapsed_seconds, cpu_percentage, threads, stack_committed_mb, \
stack_reserved_mb, heap_used_mb, eden_mb, s0_kb, s1_kb, old_mb, meta_mb, \
compressed_class_mb, ygc, ygct, fgc, fgct, cgc, cgct, gct" > $LOG_FILE
while true; do
    # 1. System metrics
    CPU=$(top -b -n 2 -d 1 | grep "java" | tail -1 | awk '{print $9}')
    # Capture the elapsed time and convert etime to seconds in one go
    ETIME=$(ps -p $PID -o etime= | awk '{
        split($1, t, ":");
        len = 0; for (i in t) len++;
        if (len == 3) s = t[1]*3600 + t[2]*60 + t[3];
        else if (len == 2) s = t[1]*60 + t[2];
        else s = t[1];
        print s
    }')
    THREADS=$(awk '/Threads/ {print $2}' /proc/$PID/status)

    # 2. Get native stack memory
    STACK_DATA=$(jcmd $PID VM.native_memory summary | grep "Thread")
    STK_RES_KB=$(echo "$STACK_DATA" | grep -o "reserved=[0-9]*" | cut -d= -f2)
    STK_COM_KB=$(echo "$STACK_DATA" | grep -o "committed=[0-9]*" | cut -d= -f2)
    [ -z "$STK_RES_KB" ] && STK_RES_KB=0
    [ -z "$STK_COM_KB" ] && STK_COM_KB=0

    # 3. Get internal heap breakdown and GC stats, and print all
    jstat -gc $PID | awk -v et="$ETIME" -v cp="$CPU" -v th="$THREADS" \
        -v s_com="$((STK_COM_KB/1024))" -v s_res="$((STK_RES_KB/1024))" \
        'NR==2 {
            # Heap math: S0U($3), S1U($4), EU($6), OU($8)
            total_used = ($3 + $4 + $6 + $8) / 1024;

            # jstat -gc index:
            # MU=$10, CCSC=$11, CCSU=$12, YGC=$13, YGCT=$14, FGC=$15, FGCT=$16, CGC=$17, CGCT=$18, GCT=$19
            printf "%s, %s, %s, %s, %s, %.1f, %d, %.1f, %.1f, %d, %d, %d, %d, %.3f, %d, %.3f, %d, %.3f, %.3f\n",
                   et, cp, th, s_com, s_res, total_used, $6/1024, $3, $4, $8/1024, $10/1024, $12/1024, \
                   $13, $14, $15, $16, $17, $18, $19
        }' >> $LOG_FILE
done