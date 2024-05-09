#!/bin/sh

# Get the date for today
DATE=$(date "+%Y-%m-%d")

# Calculate the date for yesterday using the shell's arithmetic
PREVIOUS_DATE=$(date -v -1d "+%Y-%m-%d")
PREVIOUS_FILE="/Library/Logs/${PREVIOUS_DATE}screentime.log"
PREVIOUS_OUTPUT_FILE="/Library/Logs/${PREVIOUS_DATE}output.log"


# Check if the file from the previous day exists and remove it
if [ -e "$PREVIOUS_FILE" ]; then
    rm "$PREVIOUS_FILE"
fi
if [ -e "$PREVIOUS_OUTPUT_FILE" ]; then
    rm "$PREVIOUS_OUTPUT_FILE"
fi

# Process the power management events for today and append to the log
pmset -g log | grep "$DATE" | grep "+1000 \(Wake  \|Sleep  \)" | awk '{print $1, $2, $4}' > "/Library/Logs/${DATE}screentime.log"

# Initialize variables
total_awake_time=0
last_event_time=0
is_awake=false

# Process each line of the file
while IFS= read -r line; do
    timestamp=$(echo "$line" | awk '{print $1, $2}')
    event_type=$(echo "$line" | awk '{print $3}')

    if [ "$event_type" = "Wake" ]; then
        is_awake=true
        last_event_time=$(date -j -f "%Y-%m-%d %H:%M:%S" "$timestamp" "+%s")
    elif [ "$event_type" = "Sleep" ]; then
        if [ "$is_awake" = true ]; then
            current_event_time=$(date -j -f "%Y-%m-%d %H:%M:%S" "$timestamp" "+%s")
            awake_duration=$((current_event_time - last_event_time))
            total_awake_time=$((total_awake_time + awake_duration))
            is_awake=false
        fi
    fi
done < "/Library/Logs/${DATE}screentime.log"

# Convert total_awake_time to HH:MM:SS format
awake_hours=$((total_awake_time / 3600))
awake_minutes=$(( (total_awake_time % 3600) / 60 ))
awake_seconds=$((total_awake_time % 60))

echo "$awake_hours hours, $awake_minutes minutes, $awake_seconds seconds" > "/Library/Logs/${DATE}output.log"
