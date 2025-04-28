#!/bin/bash
set -e

# Default paths
CONFIG_PATH="/app/config/config.yaml"
SCHEDULE_PATH="/app/config/bot.yaml"
YQ="/usr/local/bin/yq"
ITEMS_CSV="/app/output/items.csv"
MAX_AGE_SECONDS=518400  # 6 days

# Check if yq is available
if ! command -v $YQ &> /dev/null; then
  echo "ERROR: yq is required for parsing YAML config" >&2
  exit 1
fi

# Function to run ffxiahbot
run_ffxiahbot() {
  local subcommand=$1
  local options=$2
  # Add --no-prompt for refill
  if [ "$subcommand" = "refill" ]; then
    options="$options --no-prompt"
  fi
  echo "DEBUG: Running ffxiahbot $subcommand with options: $options --config $CONFIG_PATH"
  /usr/local/bin/ffxiahbot "$subcommand" $options --config "$CONFIG_PATH"
}

# Log database settings from environment (for debugging)
echo "DEBUG: Database settings: FFXIAHBOT_DB_HOST=$FFXIAHBOT_DB_HOST, FFXIAHBOT_DB_PORT=$FFXIAHBOT_DB_PORT, FFXIAHBOT_DB_USER=$FFXIAHBOT_DB_USER, FFXIAHBOT_DB_NAME=$FFXIAHBOT_DB_NAME"

# Check if items.csv needs updating
RUN_SCRUB="true"
if [ -f "$ITEMS_CSV" ]; then
  CURRENT_TIME=$(date +%s)
  FILE_MTIME=$(stat -c %Y "$ITEMS_CSV" 2>/dev/null || echo 0)
  FILE_AGE=$((CURRENT_TIME - FILE_MTIME))
  if [ "$FILE_AGE" -le "$MAX_AGE_SECONDS" ]; then
    echo "DEBUG: $ITEMS_CSV is recent (age: $FILE_AGE seconds), skipping scrub"
    RUN_SCRUB="false"
  else
    echo "DEBUG: $ITEMS_CSV is old (age: $FILE_AGE seconds), running scrub"
  fi
else
  echo "DEBUG: $ITEMS_CSV does not exist, running scrub"
fi

# Manual mode
if [ "$BOT_MODE" = "manual" ]; then
  SUBCOMMAND=$($YQ e '.manual.subcommand' "$SCHEDULE_PATH")
  OPTIONS=$($YQ e '.manual.options | to_entries | .[] | select(.key != "overwrite") | "--" + (.key | sub("_", "-")) + " " + (.value | tostring)' "$SCHEDULE_PATH" | tr '\n' ' ')
  OVERWRITE=$($YQ e '.manual.options.overwrite' "$SCHEDULE_PATH")
  if [ "$OVERWRITE" = "true" ]; then
    OPTIONS="$OPTIONS --overwrite"
  fi
  run_ffxiahbot "$SUBCOMMAND" "$OPTIONS"
  exit 0
fi

# Scheduled mode: check for clear first
CLEAR_ENABLED=$($YQ e '.scheduled.clear' "$SCHEDULE_PATH")
if [ "$CLEAR_ENABLED" = "[x]" ]; then
  OPTIONS=$($YQ e '.options.clear | to_entries | .[] | select(.key != "overwrite") | "--" + (.key | sub("_", "-")) + " " + (.value | tostring)' "$SCHEDULE_PATH" | tr '\n' ' ')
  OVERWRITE=$($YQ e '.options.clear.overwrite' "$SCHEDULE_PATH")
  if [ "$OVERWRITE" = "true" ]; then
    OPTIONS="$OPTIONS --overwrite"
  fi
  run_ffxiahbot "clear" "$OPTIONS"
  exit 0
fi

# Run other enabled actions in order: scrub, refill, broker
for SUBCOMMAND in scrub refill broker; do
  ENABLED=$($YQ e ".scheduled.$SUBCOMMAND" "$SCHEDULE_PATH")
  if [ "$ENABLED" = "[x]" ]; then
    # Skip scrub if not needed
    if [ "$SUBCOMMAND" = "scrub" ] && [ "$RUN_SCRUB" = "false" ]; then
      echo "DEBUG: Skipping $SUBCOMMAND due to recent $ITEMS_CSV"
      continue
    fi
    OPTIONS=$($YQ e ".options.$SUBCOMMAND | to_entries | .[] | select(.key != \"overwrite\") | \"--\" + (.key | sub(\"_\", \"-\")) + \" \" + (.value | tostring)" "$SCHEDULE_PATH" | tr '\n' ' ')
    OVERWRITE=$($YQ e ".options.$SUBCOMMAND.overwrite" "$SCHEDULE_PATH")
    if [ "$OVERWRITE" = "true" ]; then
      OPTIONS="$OPTIONS --overwrite"
    fi
    run_ffxiahbot "$SUBCOMMAND" "$OPTIONS"
  fi
done
