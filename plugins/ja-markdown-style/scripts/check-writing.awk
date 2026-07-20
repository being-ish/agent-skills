BEGIN {
  in_code_block = 0
  violations = 0
  kana = "ぁ-んァ-ヶー一-龠"
  alnum = "0-9A-Za-z"
}

function report(msg) {
  print lineno ": " msg ": " $0 > "/dev/stderr"
  violations++
}

{
  lineno = NR

  if ($0 ~ /^[[:space:]]*```/) {
    in_code_block = !in_code_block
    next
  }
  if (in_code_block) next

  # コードスパンを除外してから検査する
  checked = $0
  gsub(/`[^`]*`/, "", checked)

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
    report("文末コロンで列挙・説明を導入せず地の文で書いてください")
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
  if (checked ~ /^[[:space:]]*([-*]|[0-9]+\.) / && index(checked, "。") > 0) {
    report("箇条書き内で句点「。」が使われています。1 アイテム 1 文に直し、複数文は下位項目にぶら下げてください")
  }

  # 文中列挙の中黒
  if (index(checked, "・") > 0) {
    report("文中列挙の区切りに中黒「・」を使わず読点「、」を使ってください")
  }
}

END {
  if (violations > 0) {
    print "日本語表記規則の違反が見つかりました。" > "/dev/stderr"
    exit 2
  }
  exit 0
}
