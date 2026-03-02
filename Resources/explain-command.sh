#!/bin/bash
# Claude Code PreToolUse Hook: Bash コマンドの解説表示 + UI許可/拒否

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
[ "$TOOL_NAME" != "Bash" ] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0

MAIN_CMD=$(echo "$COMMAND" | sed 's/^[A-Z_]*=[^ ]* //; s/^sudo //' | awk '{print $1}' | sed 's|.*/||')
[ -z "$MAIN_CMD" ] && exit 0

# allowlist チェック: ずっと許可されたコマンドは即座に許可
ALLOW_FILE="$HOME/.config/iruka-kun/allowed-main-cmds.txt"
if [ -f "$ALLOW_FILE" ] && grep -qFx "$MAIN_CMD" "$ALLOW_FILE"; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow"}}'
  exit 0
fi

# Claude Code の許可設定をチェック: 既に許可済みなら解説をスキップ
for _SETTINGS in ".claude/settings.local.json" "$HOME/.claude/settings.json"; do
  if [ -f "$_SETTINGS" ]; then
    if jq -r '.permissions.allow[]?' "$_SETTINGS" 2>/dev/null | grep -qE "^Bash\(${MAIN_CMD}([^a-zA-Z0-9_-]|$)"; then
      exit 0
    fi
  fi
done

# tldr(日本語) → tldr(英語) → whatis の順で解説を取得
EXPLANATION=""
if command -v tldr &>/dev/null; then
  EXPLANATION=$(tldr -L ja "$MAIN_CMD" 2>/dev/null | head -10)
  [ -z "$EXPLANATION" ] && EXPLANATION=$(tldr "$MAIN_CMD" 2>/dev/null | head -10)
fi
[ -z "$EXPLANATION" ] && EXPLANATION=$(whatis "$MAIN_CMD" 2>/dev/null | head -3)
[ -z "$EXPLANATION" ] && exit 0

# stderr に出力（ターミナルへの即時フィードバック）
INTROS=(
  "このコマンドはね〜"
  "おしえてあげる！"
  "これはこういうコマンドだよ〜"
  "知ってる？これはね〜"
  "いっしょに勉強しよ！"
)
INTRO=${INTROS[$((RANDOM % ${#INTROS[@]}))]}

echo "" >&2
echo "🐬 イルカ「${INTRO}」 — $MAIN_CMD" >&2
echo "─────────────────────────" >&2
echo "$EXPLANATION" >&2
echo "" >&2

# JSON に show 状態で書き出し（翻訳不要なので即座に表示可能）
jq -n --arg cmd "$MAIN_CMD" --arg exp "$EXPLANATION" --arg ts "$(date +%s)$$" \
  '{command: $cmd, explanation: $exp, timestamp: $ts, status: "show"}' \
  > /tmp/iruka-kun-command-explain.json 2>/dev/null

# UI からの許可/拒否をポーリング
RESPONSE_FILE="/tmp/iruka-kun-command-response.json"
rm -f "$RESPONSE_FILE"

WAITED=0
MAX_WAIT=166  # 0.3秒 × 166 ≈ 50秒
while [ "$WAITED" -lt "$MAX_WAIT" ]; do
  if [ -f "$RESPONSE_FILE" ]; then
    DECISION=$(jq -r '.decision // empty' "$RESPONSE_FILE" 2>/dev/null)
    case "$DECISION" in
      allow)
        jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow"}}'
        rm -f "$RESPONSE_FILE"
        exit 0 ;;
      allowAlways)
        mkdir -p "$(dirname "$ALLOW_FILE")"
        echo "$MAIN_CMD" >> "$ALLOW_FILE"
        jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow"}}'
        rm -f "$RESPONSE_FILE"
        exit 0 ;;
      deny)
        jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"イルカくんから拒否されました"}}'
        rm -f "$RESPONSE_FILE"
        exit 0 ;;
    esac
  fi
  sleep 0.3
  WAITED=$((WAITED + 1))
done

# タイムアウト → 通常のClaude Codeフローにフォールバック
exit 0
