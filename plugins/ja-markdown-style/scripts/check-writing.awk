BEGIN {
  in_code_block = 0
  in_frontmatter = 0
  violations = 0
  kana = "ぁ-んァ-ヶー一-龠"
  alnum = "0-9A-Za-z"

  # 文書設定取得用
  in_being_ish = 0
  kind = ""

  # 文書ごとに適用するチェックを定義
  skip["legal", "list-period"] = 1
}

function report(msg) {
  print lineno ": " msg ": " $0 > "/dev/stderr"
  violations++
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
  if (checked ~ ("[" kana "][" alnum "]") || checked ~ ("[" alnum "][" kana "]")) {
    report("和文と半角英数字の間に半角スペースがありません")
  }

  # ダッシュ「—」
  if (checked ~ /—/) {
    report("ダッシュ「—」を使わず読点で区切るか文を分けてください")
  }

  # 文末コロン(欧文式の列挙導入)
  if (checked ~ /[:：][[:space:]]*$/) {
    report("文末コロンで列挙や説明を繋げず、地の文で書いてください")
  }

  # §
  if (checked ~ /§/) {
    report("「§」を使わず「9.1 節」のように書いてください")
  }

  # 「以下のように」
  if (index(checked, "以下のように") > 0) {
    report("「以下のように」を使わず範囲を明示してください")
  }

  # 箇条書きネストのインデント
  if (match(checked, /^[[:space:]]*[-*] /)) {
    indent = RLENGTH - 2
    if (indent % 4 != 0) {
      report("箇条書きのインデントは半角スペース 4 の倍数にしてください")
    }
  }

  # 箇条書きは 1 アイテム 1 文
  if (!((kind, "list-period") in skip) && checked ~ /^[[:space:]]*([-*]|[0-9]+\.) / && index(checked, "。") > 0) {
    report("箇条書き内で句点「。」が使われています。1 アイテム 1 文に直し、複数文は下位項目にぶら下げてください")
  }
}

END {
  if (violations > 0) {
    print "日本語表記規則の違反が見つかりました。" > "/dev/stderr"
    exit 2
  }
  exit 0
}
