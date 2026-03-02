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
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
for _SETTINGS in \
  "${_PROJECT_ROOT:+$_PROJECT_ROOT/.claude/settings.local.json}" \
  ".claude/settings.local.json" \
  "$HOME/.claude/settings.json"; do
  [ -z "$_SETTINGS" ] && continue
  [ -f "$_SETTINGS" ] || continue
  if jq -r '.permissions.allow[]?' "$_SETTINGS" 2>/dev/null | grep -qE "^Bash\(${MAIN_CMD}([^a-zA-Z0-9_-]|$)"; then
    exit 0
  fi
done

# フォールバックチェーン: 日本語tldrページ直接読み → 英語tldr → whatis
TLDR_BASE="${HOME}/.tldrc/tldr"
EXPLANATION=""

# 1. 日本語 tldr ページを直接読み込み (osx 優先、次に common)
if [ -d "$TLDR_BASE/pages.ja" ]; then
  for _DIR in osx common linux; do
    _PAGE="$TLDR_BASE/pages.ja/$_DIR/${MAIN_CMD}.md"
    if [ -f "$_PAGE" ]; then
      EXPLANATION=$(head -20 "$_PAGE")
      break
    fi
  done
fi

# 2. 英語 tldr (コマンド経由 -- pages.ja にない場合)
if [ -z "$EXPLANATION" ]; then
  if command -v tldr &>/dev/null; then
    EXPLANATION=$(tldr "$MAIN_CMD" 2>/dev/null | head -10)
  fi
fi

# 3. whatis (最終フォールバック)
[ -z "$EXPLANATION" ] && EXPLANATION=$(whatis "$MAIN_CMD" 2>/dev/null | head -3)
[ -z "$EXPLANATION" ] && exit 0

# tldr ページの定期更新（週1回、バックグラウンド）
if command -v tldr &>/dev/null; then
  TLDR_UPDATE_MARKER="/tmp/iruka-kun-tldr-last-update"
  _NEED_UPDATE=false
  if [ ! -f "$TLDR_UPDATE_MARKER" ]; then
    _NEED_UPDATE=true
  else
    _LAST_UPDATE=$(stat -f %m "$TLDR_UPDATE_MARKER" 2>/dev/null || echo 0)
    _NOW=$(date +%s)
    [ $((_NOW - _LAST_UPDATE)) -gt $((7*24*60*60)) ] && _NEED_UPDATE=true
  fi
  [ "$_NEED_UPDATE" = true ] && (tldr --update &>/dev/null && touch "$TLDR_UPDATE_MARKER") &
fi

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
