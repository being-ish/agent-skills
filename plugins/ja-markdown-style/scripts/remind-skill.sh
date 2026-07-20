#!/bin/sh
# Markdown を書く前に ja-markdown-style スキルの指針を思い出させる
set -u

input=$(cat)

file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [ -z "$file_path" ]; then
  exit 0
fi

case "$file_path" in
  *.md) ;;
  *) exit 0 ;;
esac

cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"日本語 Markdown を書く前に ja-markdown-style スキルの指針に従うこと"}}
EOF

exit 0
