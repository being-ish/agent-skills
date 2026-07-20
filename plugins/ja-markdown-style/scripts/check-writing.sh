#!/bin/sh
# Write / Edit された Markdown の日本語表記規則を検査する
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

if [ ! -f "$file_path" ]; then
  exit 0
fi

if ! command -v awk >/dev/null 2>&1; then
  exit 0
fi

# 日本語のブラケット範囲を扱うため UTF-8 ロケールを選ぶ
LC_ALL=""
for candidate in ja_JP.UTF-8 en_US.UTF-8 C.UTF-8; do
  if locale -a 2>/dev/null | grep -qx "$candidate"; then
    LC_ALL="$candidate"
    break
  fi
done
if [ -z "$LC_ALL" ]; then
  exit 0
fi
export LC_ALL

script_dir=$(dirname "$0")
awk -f "$script_dir/check-writing.awk" "$file_path"

exit $?
