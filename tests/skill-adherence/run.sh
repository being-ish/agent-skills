#!/bin/sh

# skill-adherence プラグインの detect-skill-usage.sh をテストする
# 成果物の実在チェックがあるため、transcript は tmpdir に実ファイルを作って動的に生成する

set -u

cd "$(dirname "$0")/../.." || exit 1

SCRIPT="plugins/skill-adherence/scripts/detect-skill-usage.sh"

tmpdir=$(mktemp -d) || exit 1
trap 'rm -rf "$tmpdir"' EXIT

failures=0

assert_exit() {
  desc="$1"
  expected="$2"
  actual="$3"
  if [ "$expected" != "$actual" ]; then
    echo "NG: $desc: exit code は $expected を期待したが $actual だった" >&2
    failures=$((failures + 1))
  else
    echo "OK: $desc"
  fi
}

assert_contains() {
  desc="$1"
  haystack="$2"
  needle="$3"
  case "$haystack" in
    *"$needle"*)
      echo "OK: $desc"
      ;;
    *)
      echo "NG: $desc: 出力に \"$needle\" が含まれない" >&2
      failures=$((failures + 1))
      ;;
  esac
}

assert_empty() {
  desc="$1"
  out="$2"
  if [ -n "$out" ]; then
    echo "NG: $desc: 出力が空でない: $out" >&2
    failures=$((failures + 1))
  else
    echo "OK: $desc"
  fi
}

# tool_use 1 件を含む assistant 行を JSONL として書く
append_tool_use() {
  transcript="$1"
  tool="$2"
  input_json="$3"
  jq -nc --arg tool "$tool" --argjson inp "$input_json" \
    '{type: "assistant", message: {content: [{type: "tool_use", name: $tool, input: $inp}]}}' \
    >> "$transcript"
}

run_detect() {
  transcript="$1"
  active="${2:-false}"
  jq -n --arg tp "$transcript" --argjson active "$active" \
    '{transcript_path: $tp, stop_hook_active: $active}' \
    | SKILL_ADHERENCE_INSTALLED_PLUGINS="$installed_plugins" sh "$SCRIPT" 2>&1
}

artifact="$tmpdir/artifact.md"
echo "# doc" > "$artifact"

# being-ish に dev-docs だけがインストールされている状態のフィクスチャー
installed_plugins="$tmpdir/installed_plugins.json"
cat > "$installed_plugins" <<'EOF'
{
  "plugins": {
    "dev-docs@being-ish": [{"scope": "user"}],
    "some-skill@some-vendor": [{"scope": "user"}]
  }
}
EOF

# Skill 使用あり + 編集あり → block
t="$tmpdir/both.jsonl"
: > "$t"
append_tool_use "$t" "Skill" '{"skill": "dev-docs:adr"}'
append_tool_use "$t" "Write" "{\"file_path\": \"$artifact\"}"
out=$(run_detect "$t")
rc=$?
assert_exit "both: exit code" 0 "$rc"
assert_contains "both: decision block" "$out" '"decision": "block"'
assert_contains "both: sub-agent 起動指示" "$out" "skill-adherence:skill-adherence-checker"
assert_contains "both: Skill 名" "$out" "dev-docs:adr"
assert_contains "both: 成果物パス" "$out" "$artifact"

# Skill 使用なし → 何も出力しない
t="$tmpdir/no-skill.jsonl"
: > "$t"
append_tool_use "$t" "Write" "{\"file_path\": \"$artifact\"}"
out=$(run_detect "$t")
rc=$?
assert_exit "no-skill: exit code" 0 "$rc"
assert_empty "no-skill: 出力なし" "$out"

# 編集なし → 何も出力しない
t="$tmpdir/no-edit.jsonl"
: > "$t"
append_tool_use "$t" "Skill" '{"skill": "dev-docs:adr"}'
out=$(run_detect "$t")
rc=$?
assert_exit "no-edit: exit code" 0 "$rc"
assert_empty "no-edit: 出力なし" "$out"

# being-ish 以外の Skill のみ → 何も出力しない
t="$tmpdir/other-skill.jsonl"
: > "$t"
append_tool_use "$t" "Skill" '{"skill": "some-vendor:some-skill"}'
append_tool_use "$t" "Write" "{\"file_path\": \"$artifact\"}"
out=$(run_detect "$t")
rc=$?
assert_exit "other-skill: exit code" 0 "$rc"
assert_empty "other-skill: 出力なし" "$out"

# 編集ファイルが現存しない → 何も出力しない
t="$tmpdir/deleted.jsonl"
: > "$t"
append_tool_use "$t" "Skill" '{"skill": "dev-docs:adr"}'
append_tool_use "$t" "Write" "{\"file_path\": \"$tmpdir/gone.md\"}"
out=$(run_detect "$t")
rc=$?
assert_exit "deleted: exit code" 0 "$rc"
assert_empty "deleted: 出力なし" "$out"

# stop_hook_active → 何も出力しない
t="$tmpdir/active.jsonl"
: > "$t"
append_tool_use "$t" "Skill" '{"skill": "dev-docs:adr"}'
append_tool_use "$t" "Write" "{\"file_path\": \"$artifact\"}"
out=$(run_detect "$t" true)
rc=$?
assert_exit "active: exit code" 0 "$rc"
assert_empty "active: 出力なし" "$out"

# checker を起動済み → 何も出力しない
t="$tmpdir/checked.jsonl"
: > "$t"
append_tool_use "$t" "Skill" '{"skill": "dev-docs:adr"}'
append_tool_use "$t" "Write" "{\"file_path\": \"$artifact\"}"
append_tool_use "$t" "Task" '{"subagent_type": "skill-adherence:skill-adherence-checker"}'
out=$(run_detect "$t")
rc=$?
assert_exit "checked: exit code" 0 "$rc"
assert_empty "checked: 出力なし" "$out"

# 別の sub-agent の起動は checker 実施とみなさない
t="$tmpdir/other-agent.jsonl"
: > "$t"
append_tool_use "$t" "Skill" '{"skill": "dev-docs:adr"}'
append_tool_use "$t" "Write" "{\"file_path\": \"$artifact\"}"
append_tool_use "$t" "Task" '{"subagent_type": "general-purpose"}'
out=$(run_detect "$t")
rc=$?
assert_exit "other-agent: exit code" 0 "$rc"
assert_contains "other-agent: decision block" "$out" '"decision": "block"'

# installed_plugins.json がない → 何も出力しない
t="$tmpdir/no-installed.jsonl"
: > "$t"
append_tool_use "$t" "Skill" '{"skill": "dev-docs:adr"}'
append_tool_use "$t" "Write" "{\"file_path\": \"$artifact\"}"
out=$(jq -n --arg tp "$t" '{transcript_path: $tp, stop_hook_active: false}' \
  | SKILL_ADHERENCE_INSTALLED_PLUGINS="$tmpdir/missing.json" sh "$SCRIPT" 2>&1)
rc=$?
assert_exit "no-installed: exit code" 0 "$rc"
assert_empty "no-installed: 出力なし" "$out"

# transcript_path が JSON にない → 何も出力しない
out=$(printf '{}' | sh "$SCRIPT" 2>&1)
rc=$?
assert_exit "no transcript: exit code" 0 "$rc"
assert_empty "no transcript: 出力なし" "$out"

if [ "$failures" -gt 0 ]; then
  echo "テスト失敗: $failures 件" >&2
  exit 1
fi

echo "テスト成功"
