#!/bin/bash
# Claude Code Notification Hook: pending な解説を show に昇格

FILE=/tmp/iruka-kun-command-explain.json
LOG=/tmp/iruka-kun-hook-debug.log
echo "$(date): notify-explain called" >> "$LOG"
if [ -f "$FILE" ]; then
  STATUS=$(jq -r '.status // empty' "$FILE" 2>/dev/null)
  echo "$(date): status=$STATUS" >> "$LOG"
  if [ "$STATUS" = "pending" ]; then
    CONTENT=$(jq '.status = "show"' "$FILE")
    echo "$CONTENT" > "$FILE"
    echo "$(date): changed to show" >> "$LOG"
  fi
fi

exit 0
