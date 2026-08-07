BEGIN {
  in_code_block = 0
  in_frontmatter = 0
  violations = 0
  kana = "ぁ-んァ-ヶー一-龠"
  alnum = "0-9A-Za-z"

  # 文書設定取得用
  in_being_ish = 0
  kind = ""

  # 箇条書き 1 アイテム 1 文チェックの識別子
  CHECK_LIST_PERIOD = "list-period"

  # 文書ごとに適用するチェックを定義
  skip["legal", CHECK_LIST_PERIOD] = 1
}

function count_matches(s, re,    n) {
  n = 0
  while (match(s, re)) {
    n++
    s = substr(s, RSTART + RLENGTH)
  }
  return n
}

function report(msg, n) {
  if (n == "") n = 1
  if (n < 1) return
  print lineno ": " msg (n > 1 ? " (" n " 箇所)" : "") ": " $0 > "/dev/stderr"
  violations += n
}

{
  lineno = NR

  if (NR == 1 && $0 ~ /^---[[:space:]]*$/) {
    in_frontmatter = 1
    next
  }
  if (in_frontmatter) {
    if ($0 ~ /^(---|\.\.\.)[[:space:]]*$/) in_frontmatter = 0
    else if ($0 ~ /^being-ish:[[:space:]]*$/) in_being_ish = 1
    else if ($0 ~ /^[^[:space:]]/) in_being_ish = 0
    else if (in_being_ish && match($0, /^[[:space:]]+kind:[[:space:]]*/)) {
      kind = substr($0, RLENGTH + 1)
      sub(/[[:space:]]+$/, "", kind)
      gsub(/["']/, "", kind)
    }
    next
  }

  if ($0 ~ /^[[:space:]]*```/) {
    in_code_block = !in_code_block
    next
  }
  if (in_code_block) next

  # 引用は原文のまま書くため検査しない
  if ($0 ~ /^[[:space:]]*([-*] |[0-9]+\. )?>/) next

  # コードスパンとインライン引用を除外してから検査する
  checked = $0
  gsub(/`[^`]*`/, "", checked)
  gsub(/<q>[^<]*<\/q>/, "", checked)

  # 和文と半角英数字の間のスペース
  n = count_matches(checked, "[" kana "][" alnum "]") + count_matches(checked, "[" alnum "][" kana "]")
  if (n > 0) {
    report("和文と半角英数字の間に半角スペースがありません", n)
  }

  # ダッシュ「—」
  report("ダッシュ「—」を使わず読点で区切るか文を分けてください", count_matches(checked, "—"))

  # 文末コロン(欧文式の列挙導入)
  if (checked ~ /[:：][[:space:]]*$/) {
    report("文末コロンで列挙や説明を繋げず、地の文で書いてください")
  }

  # §
  report("「§」を使わず「9.1 節」のように書いてください", count_matches(checked, "§"))

  # 「以下のように」
  report("「以下のように」を使わず範囲を明示してください", count_matches(checked, "以下のように"))

  # 箇条書きネストのインデント
  if (match(checked, /^[[:space:]]*[-*] /)) {
    indent = RLENGTH - 2
    if (indent % 4 != 0) {
      report("箇条書きのインデントは半角スペース 4 の倍数にしてください")
    }
  }

  # 箇条書きは 1 アイテム 1 文
  if (!((kind, CHECK_LIST_PERIOD) in skip) && checked ~ /^[[:space:]]*([-*]|[0-9]+\.) /) {
    report("箇条書き内で句点「。」が使われています。1 アイテム 1 文に直し、複数文は下位項目にぶら下げてください", count_matches(checked, "。"))
  }
}

END {
  if (violations > 0) {
    print "日本語表記規則の違反が見つかりました。" > "/dev/stderr"
    exit 2
  }
  exit 0
}
