#!/bin/bash
set -e

# Write key parameters into the log file
echo "$(date +'%Y-%m-%d %H:%M:%S')" > "$LOG_DIR/out.log"
cat /proc/self/limits | grep "Max open files" >> "$LOG_DIR/out.log"
echo "APP: $APP" >> "$LOG_DIR/out.log"
echo "JAVA_OPTS: $JAVA_OPTS" >> "$LOG_DIR/out.log"

# Start Java in the background
java $JAVA_OPTS -jar $APP.jar >> "$LOG_DIR/out.log" 2>&1 &

# Wait for Java to at least start the process
sleep 1

# Execute the monitoring script in the foreground
# (This keeps the container alive)
bash /app/usage.sh >/dev/null
