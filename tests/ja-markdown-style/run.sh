#!/bin/sh

# ja-markdown-style プラグインの check-writing.sh をテストする
# .md で置くとこのリポジトリー自身の表記チェック Hook に引っかかるため、フィクスチャーは .txt で置き、検査対象拡張子にコピーしてから検証する
# 対象外拡張子の確認は .txt のまま渡せばよいためコピーしない

set -u

cd "$(dirname "$0")/../.." || exit 1

SCRIPT="plugins/ja-markdown-style/scripts/check-writing.sh"
FIXTURES="tests/ja-markdown-style/fixtures"

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

run_check() {
  file="$1"
  jq -n --arg fp "$file" '{tool_input:{file_path:$fp}}' | sh "$SCRIPT" 2>&1
}

# 違反ありの文書
cp "$FIXTURES/violations.txt" "$tmpdir/violations.md"
out=$(run_check "$tmpdir/violations.md")
rc=$?
assert_exit "violations: exit code" 2 "$rc"
assert_contains "violations: 和文英数字スペース" "$out" "和文と半角英数字の間に半角スペースがありません"
assert_contains "violations: ダッシュ" "$out" "ダッシュ「—」を使わず読点で区切るか文を分けてください"
assert_contains "violations: 文末コロン" "$out" "文末コロンで列挙・説明を導入せず地の文で書いてください"
assert_contains "violations: §" "$out" "「§」を使わず「9.1 節」のように書いてください"
assert_contains "violations: 以下のように" "$out" "「以下のように」を使わず範囲を明示してください"
assert_contains "violations: インデント" "$out" "箇条書きのインデントは半角スペース 4 の倍数にしてください"
assert_contains "violations: 1アイテム1文" "$out" "箇条書き内で句点「。」が使われています"
assert_contains "violations: 中黒" "$out" "文中列挙の区切りに中黒「・」を使わず読点「、」を使ってください"

# 違反なしの文書
cp "$FIXTURES/clean.txt" "$tmpdir/clean.md"
out=$(run_check "$tmpdir/clean.md")
rc=$?
assert_exit "clean: exit code" 0 "$rc"
if [ -n "$out" ]; then
  echo "NG: clean: 出力が空でない: $out" >&2
  failures=$((failures + 1))
else
  echo "OK: clean: 出力が空"
fi

# 対象外拡張子
# 違反を含む内容でも検査自体が走らないことを確認する
out=$(run_check "$FIXTURES/violations.txt")
rc=$?
assert_exit "skip: exit code" 0 "$rc"
if [ -n "$out" ]; then
  echo "NG: skip: 出力が空でない: $out" >&2
  failures=$((failures + 1))
else
  echo "OK: skip: 出力が空"
fi

# file_path が JSON にない
out=$(printf '{}' | sh "$SCRIPT" 2>&1)
rc=$?
assert_exit "no file_path: exit code" 0 "$rc"

if [ "$failures" -gt 0 ]; then
  echo "テスト失敗: $failures 件" >&2
  exit 1
fi

echo "テスト成功"
