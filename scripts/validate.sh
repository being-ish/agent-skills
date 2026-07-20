#!/bin/sh
# マーケットプレイスとプラグインのマニフェスト整合性を検証する
set -u

cd "$(dirname "$0")/.." || exit 1

MARKETPLACE=".claude-plugin/marketplace.json"
errors=0

fail() {
  echo "NG: $1" >&2
  errors=$((errors + 1))
}

if ! command -v claude >/dev/null 2>&1; then
  fail "claude コマンドが見つからない"
else
  if ! claude plugin validate .; then
    fail "marketplace.json の claude plugin validate に失敗した"
  fi
fi

if ! jq empty "$MARKETPLACE" 2>/dev/null; then
  fail "$MARKETPLACE が JSON としてパースできない"
  exit 1
fi

tab=$(printf '\t')
plugin_list=$(jq -r '.plugins[] | [.name, .source] | @tsv' "$MARKETPLACE")

while IFS="$tab" read -r name source; do
  manifest="$source/.claude-plugin/plugin.json"
  if ! jq empty "$manifest" 2>/dev/null; then
    continue
  fi

  plugin_name=$(jq -r '.name' "$manifest")
  if [ "$plugin_name" != "$name" ]; then
    fail "$name: $manifest の name が \"$plugin_name\" と一致しない"
  fi

  has_skill=0
  has_hooks=0
  ls "$source"/skills/*/SKILL.md >/dev/null 2>&1 && has_skill=1
  [ -f "$source/hooks/hooks.json" ] && has_hooks=1

  if [ "$has_skill" -eq 0 ] && [ "$has_hooks" -eq 0 ]; then
    fail "$name: $source/skills/*/SKILL.md も $source/hooks/hooks.json も存在しない"
  fi

  if [ "$has_hooks" -eq 1 ] && ! jq empty "$source/hooks/hooks.json" 2>/dev/null; then
    fail "$name: $source/hooks/hooks.json が JSON としてパースできない"
  fi
done <<EOF
$plugin_list
EOF

if [ "$errors" -gt 0 ]; then
  echo "検証失敗: $errors 件" >&2
  exit 1
fi

echo "検証成功"
