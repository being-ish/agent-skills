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

if ! jq empty "$MARKETPLACE" 2>/dev/null; then
  fail "$MARKETPLACE が JSON としてパースできない"
  exit 1
fi

plugin_root=$(jq -r '.metadata.pluginRoot // "./plugins"' "$MARKETPLACE")
tab=$(printf '\t')
plugin_list=$(jq -r '.plugins[] | [.name, .source] | @tsv' "$MARKETPLACE")

while IFS="$tab" read -r name source; do
  dir="$plugin_root/$source"
  if [ ! -d "$dir" ]; then
    fail "$name: ディレクトリ $dir が存在しない"
    continue
  fi

  manifest="$dir/.claude-plugin/plugin.json"
  if [ ! -f "$manifest" ]; then
    fail "$name: $manifest が存在しない"
    continue
  fi

  if ! jq empty "$manifest" 2>/dev/null; then
    fail "$name: $manifest が JSON としてパースできない"
    continue
  fi

  plugin_name=$(jq -r '.name' "$manifest")
  if [ "$plugin_name" != "$name" ]; then
    fail "$name: $manifest の name が \"$plugin_name\" で一致しない"
  fi

  if ! ls "$dir"/skills/*/SKILL.md >/dev/null 2>&1; then
    fail "$name: $dir/skills/*/SKILL.md が存在しない"
  fi
done <<EOF
$plugin_list
EOF

if [ "$errors" -gt 0 ]; then
  echo "検証失敗: $errors 件" >&2
  exit 1
fi

echo "検証成功"
