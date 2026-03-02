#!/bin/bash
# Claude Code PreToolUse Hook: Bash コマンドの解説をイルカくんに表示
# 許可/拒否は Claude Code のデフォルトに委ねる

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
[ "$TOOL_NAME" != "Bash" ] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0

MAIN_CMD=$(echo "$COMMAND" | sed 's/^[A-Z_]*=[^ ]* //; s/^sudo //' | awk '{print $1}' | sed 's|.*/||')
[ -z "$MAIN_CMD" ] && exit 0

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

# JSON に show 状態で書き出し（イルカくん UI 向け）
jq -n --arg cmd "$MAIN_CMD" --arg exp "$EXPLANATION" --arg ts "$(date +%s)$$" \
  '{command: $cmd, explanation: $exp, timestamp: $ts, status: "show"}' \
  > /tmp/iruka-kun-command-explain.json 2>/dev/null

# 許可/拒否は Claude Code のデフォルトに任せる
exit 0
