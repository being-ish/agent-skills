#!/bin/sh

# skill-adherence プラグインの detect-skill-usage.sh をテストする
# インストール済み plugin の情報とその installPath 配下の skills を参照するため、両方を tmpdir に用意する

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

log_dir="$tmpdir/log"
log_file="$log_dir/fallback.log"

run_detect() {
  transcript="$1"
  active="${2:-false}"
  installed="${3:-$installed_plugins}"
  jq -n --arg tp "$transcript" --argjson active "$active" \
    '{transcript_path: $tp, stop_hook_active: $active, session_id: "sess-1", cwd: "/work/repo"}' \
    | SKILL_ADHERENCE_INSTALLED_PLUGINS="$installed" SKILL_ADHERENCE_LOG_DIR="$log_dir" \
      sh "$SCRIPT" 2>&1
}

count_log() {
  if [ -f "$log_file" ]; then
    wc -l < "$log_file" | tr -d ' '
  else
    echo 0
  fi
}

# dev-docs が being-ish から、some-plugin が別 marketplace からインストールされた状態を作る
install_path="$tmpdir/cache/dev-docs/1.0.0"
mkdir -p "$install_path/skills/adr" "$install_path/skills/prd"
other_path="$tmpdir/cache/some-plugin/1.0.0"
mkdir -p "$other_path/skills/some-skill"

installed_plugins="$tmpdir/installed_plugins.json"
jq -n --arg dp "$install_path" --arg op "$other_path" '{
  plugins: {
    "dev-docs@being-ish": [{scope: "user", installPath: $dp}],
    "some-plugin@some-vendor": [{scope: "user", installPath: $op}]
  }
}' > "$installed_plugins"

# Skill 名が現れる → block
t="$tmpdir/used.jsonl"
echo 'Skill を dev-docs:adr で起動した' > "$t"
out=$(run_detect "$t")
rc=$?
assert_exit "used: exit code" 0 "$rc"
assert_contains "used: decision block" "$out" '"decision": "block"'
assert_contains "used: スキル起動指示" "$out" "skill-adherence スキルの手順"
assert_contains "used: 検知した Skill 名" "$out" "dev-docs:adr"

# 使っていない Skill 名は候補に含めない
case "$out" in
  *"dev-docs:prd"*)
    echo "NG: used: 使っていない Skill 名が含まれる" >&2
    failures=$((failures + 1))
    ;;
  *)
    echo "OK: used: 使っていない Skill 名は含まない"
    ;;
esac

# 発火時はログが 1 行増える
assert_exit "used: ログ行数" 1 "$(count_log)"
logged=$(tail -n 1 "$log_file")
assert_contains "used: ログの session_id" "$logged" '"session_id":"sess-1"'
assert_contains "used: ログの cwd" "$logged" '"cwd":"/work/repo"'
assert_contains "used: ログの Skill 名" "$logged" '"dev-docs:adr"'

# Skill 名が現れない → 何も出力しない
t="$tmpdir/unused.jsonl"
echo 'ファイルを編集しただけ' > "$t"
out=$(run_detect "$t")
rc=$?
assert_exit "unused: exit code" 0 "$rc"
assert_empty "unused: 出力なし" "$out"

# 別 marketplace の Skill 名だけ → 何も出力しない
t="$tmpdir/other-marketplace.jsonl"
echo 'some-plugin:some-skill を使った' > "$t"
out=$(run_detect "$t")
rc=$?
assert_exit "other-marketplace: exit code" 0 "$rc"
assert_empty "other-marketplace: 出力なし" "$out"

# checker を起動済み → 何も出力しない
t="$tmpdir/checked.jsonl"
{
  echo 'dev-docs:adr を使った'
  echo 'skill-adherence-checker を起動した'
} > "$t"
out=$(run_detect "$t")
rc=$?
assert_exit "checked: exit code" 0 "$rc"
assert_empty "checked: 出力なし" "$out"

# stop_hook_active → 何も出力しない
t="$tmpdir/active.jsonl"
echo 'dev-docs:adr を使った' > "$t"
out=$(run_detect "$t" true)
rc=$?
assert_exit "active: exit code" 0 "$rc"
assert_empty "active: 出力なし" "$out"

# installed_plugins.json がない → 何も出力しない
t="$tmpdir/no-installed.jsonl"
echo 'dev-docs:adr を使った' > "$t"
out=$(run_detect "$t" false "$tmpdir/missing.json")
rc=$?
assert_exit "no-installed: exit code" 0 "$rc"
assert_empty "no-installed: 出力なし" "$out"

# transcript_path が JSON にない → 何も出力しない
out=$(printf '{}' | sh "$SCRIPT" 2>&1)
rc=$?
assert_exit "no transcript: exit code" 0 "$rc"
assert_empty "no transcript: 出力なし" "$out"

# 発火しなかったケースではログが増えない
assert_exit "ログ行数は発火回数と一致する" 1 "$(count_log)"

if [ "$failures" -gt 0 ]; then
  echo "テスト失敗: $failures 件" >&2
  exit 1
fi

echo "テスト成功"
