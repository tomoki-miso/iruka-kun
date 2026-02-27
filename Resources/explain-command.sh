#!/bin/bash
# Claude Code PreToolUse Hook: Bash コマンドの解説を pending 状態で保存

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if [ -z "$COMMAND" ]; then
  exit 0
fi

MAIN_CMD=$(echo "$COMMAND" | sed 's/^[A-Z_]*=[^ ]* //; s/^sudo //' | awk '{print $1}' | sed 's|.*/||')

if [ -z "$MAIN_CMD" ]; then
  exit 0
fi

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
IS_JAPANESE=false

if command -v tldr &>/dev/null; then
  EXPLANATION=$(tldr -L ja "$MAIN_CMD" 2>/dev/null | head -10)
  if [ -n "$EXPLANATION" ]; then
    IS_JAPANESE=true
  else
    EXPLANATION=$(tldr "$MAIN_CMD" 2>/dev/null | head -10)
  fi
fi

if [ -z "$EXPLANATION" ]; then
  EXPLANATION=$(whatis "$MAIN_CMD" 2>/dev/null | head -3)
fi

if [ -z "$EXPLANATION" ]; then
  exit 0
fi

# 日本語でなければ claude (Haiku) で翻訳
if [ "$IS_JAPANESE" = false ] && command -v claude &>/dev/null; then
  TRANSLATED=$(claude -p --model haiku --no-session-persistence "以下のコマンド「${MAIN_CMD}」の解説を簡潔な日本語に翻訳してください。箇条書きのフォーマットを保持してください。余計な前置きは不要です。

${EXPLANATION}" 2>/dev/null)
  if [ -n "$TRANSLATED" ]; then
    EXPLANATION="$TRANSLATED"
  fi
fi

# stderr に出力
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

# pending 状態で JSON に書き出し（まだ表示しない）
TIMESTAMP=$(date +%s)$$
jq -n --arg cmd "$MAIN_CMD" --arg exp "$EXPLANATION" --arg ts "$TIMESTAMP" \
  '{command: $cmd, explanation: $exp, timestamp: $ts, status: "pending"}' \
  > /tmp/iruka-kun-command-explain.json 2>/dev/null

# レスポンスファイルをポーリングしてイルカくんUIからの許可/拒否を待つ
RESPONSE_FILE="/tmp/iruka-kun-command-response.json"
rm -f "$RESPONSE_FILE"

WAITED=0
MAX_WAIT=166  # 0.3秒 × 166 ≈ 50秒
while [ "$WAITED" -lt "$MAX_WAIT" ]; do
  if [ -f "$RESPONSE_FILE" ]; then
    DECISION=$(jq -r '.decision // empty' "$RESPONSE_FILE" 2>/dev/null)
    if [ "$DECISION" = "allow" ]; then
      jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow"}}'
      rm -f "$RESPONSE_FILE"
      exit 0
    elif [ "$DECISION" = "allowAlways" ]; then
      mkdir -p "$(dirname "$ALLOW_FILE")"
      echo "$MAIN_CMD" >> "$ALLOW_FILE"
      jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow"}}'
      rm -f "$RESPONSE_FILE"
      exit 0
    elif [ "$DECISION" = "deny" ]; then
      jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"イルカくんから拒否されました"}}'
      rm -f "$RESPONSE_FILE"
      exit 0
    fi
  fi
  sleep 0.3
  WAITED=$((WAITED + 1))
done

# タイムアウト → 通常のClaude Codeフローにフォールバック
exit 0
