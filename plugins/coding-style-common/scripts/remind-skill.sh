#!/bin/sh
# コードを書く前に coding-style-common スキルの指針を思い出させる
set -u

input=$(cat)

file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [ -z "$file_path" ]; then
  exit 0
fi

case "$file_path" in
  *.md | *.txt | *.rst | *.adoc) exit 0 ;;
  *.json | *.ini | *.csv | *.tsv | *.xml) exit 0 ;;
  *.lock | *.min.js | *.map) exit 0 ;;
  *.png | *.jpg | *.jpeg | *.gif | *.svg | *.ico | *.pdf | *.woff | *.woff2) exit 0 ;;
esac

cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"コードを書く前に coding-style-common スキルの指針に従うこと"}}
EOF

exit 0
