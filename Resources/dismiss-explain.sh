#!/bin/bash
# Claude Code PostToolUse Hook: コマンド解説を閉じる

TOOL_NAME=$(cat | jq -r '.tool_name // empty')

if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

jq -n --arg ts "$(date +%s)$$" \
  '{command: "", explanation: "", timestamp: $ts, status: "dismiss"}' \
  > /tmp/iruka-kun-command-explain.json 2>/dev/null

exit 0
