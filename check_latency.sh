#!/bin/bash
# This script checks the latency on a Netskope publisher and saves the log files when it exceeds a threshold

# Directories
LOG_DIR="$HOME/netskope_mon"
ZIP_SOURCE_DIR="$HOME/logs"

# Ensure the target directory exists
mkdir -p "$LOG_DIR"

# Target domain and latency threshold (in ms)
TARGET_DOMAIN="stitcher.npa.goskope.com"
THRESHOLD_LATENCY=100 # Adjust this value to change latency time at which script should save logs

# Ping the target domain and extract latency
LATENCY=$(ping -c 1 "$TARGET_DOMAIN" | grep 'time=' | awk -F 'time=' '{print $2}' | awk '{print $1}')
SCHEDULE_LOGFILE="$LOG_DIR/schedule.log"

# Compare latency to threshold
if [[ $(echo "$LATENCY > $THRESHOLD_LATENCY" | bc) -eq 1 ]]; then
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    echo "High Latency discovered at $TIMESTAMP" >> "$SCHEDULE_LOGFILE"

    # Run the mtr command and save the output to a timestamped file
    OUTPUT_FILE="$LOG_DIR/mtr_$TIMESTAMP.log"
    mtr -rb "$TARGET_DOMAIN" > "$OUTPUT_FILE"

    # Tar and gzip the contents of the logs directory
    ZIP_FILE="$LOG_DIR/logs_$TIMESTAMP.tar.gz"
    if [ -d "$ZIP_SOURCE_DIR" ]; then
        tar -czf "$ZIP_FILE" -C "$ZIP_SOURCE_DIR" . >/dev/null 2>&1
    else
        echo "Source directory $ZIP_SOURCE_DIR does not exist. Skipping tarball creation." >> "$OUTPUT_FILE"
    fi
fi

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
echo "Normal Latency at $TIMESTAMP" >> "$SCHEDULE_LOGFILE"
