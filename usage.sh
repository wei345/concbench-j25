#!/bin/bash
set -e

echo "time, cpu%, threads, stack_committed_mb, stack_reserved_mb, heap_used_mb, eden_mb, s0_kb, s1_kb, old_mb, meta_mb, fgc"
PID=$(pgrep java)
while true; do
    # 1. System Metrics
    CPU=$(ps -p $PID -o %cpu --no-headers | xargs)
    THREADS=$(cat /proc/$PID/status | grep Threads | awk "{print \$2}")

    # 2. Get Native Stack Memory
    STACK_DATA=$(jcmd $PID VM.native_memory summary | grep "Thread")
    STK_RES_KB=$(echo "$STACK_DATA" | grep -o "reserved=[0-9]*" | cut -d= -f2)
    STK_COM_KB=$(echo "$STACK_DATA" | grep -o "committed=[0-9]*" | cut -d= -f2)
    [ -z "$STK_RES_KB" ] && STK_RES_KB=0
    [ -z "$STK_COM_KB" ] && STK_COM_KB=0

    # 3. Get Internal Heap Breakdown and GC Stats
    # S0U=$3, S1U=$4, EU=$6, OU=$8, MU=$10, FGC=$15
    J_STATS=$(jstat -gc $PID | awk "NR==2 {print \$3,\$4,\$6,\$8,\$10,\$15}")

    # Parse Values & Total
    FGC=$(echo "$J_STATS" | awk '{print ($6 == "-" || $6 == "" ? 0 : $6)}')
    TOTAL_USED_MB=$(echo $J_STATS | awk "{print (\$1+\$2+\$3+\$4)/1024}")

    # Breakdown: (Eden|S0|S1|Old), Meta (showing KB for small survivor spaces, MB for others)
    BREAKDOWN=$(echo $J_STATS | awk "{printf \"%d, %.1f, %.1f, %d, %d\", \$3/1024, \$1, \$2, \$4/1024, \$5/1024}")

    echo "$(date +%H:%M:%S), $CPU, $THREADS, $((STK_COM_KB/1024)), $((STK_RES_KB/1024)), ${TOTAL_USED_MB}, $BREAKDOWN, $FGC" | tee -a $LOG_DIR/$APP-usage.csv

    sleep 1
done