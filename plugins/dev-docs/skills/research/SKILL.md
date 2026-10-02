---
name: research
description: research を生成、更新する。技術、仕様、市場、法規制など、判断の材料となる事実の記録に使う
---

# research の生成と更新

research は判断の材料となる事実を調べた結果を記載する。

このスキルは書き方だけを定め、調査そのものは扱わない。

## ドキュメント間の関係

各ドキュメントは、表で自分より上にあるドキュメントを前提として書く。

| ドキュメント | 書くもの |
|---|---|
| research | 判断の材料となる事実 |
| PRD | 要件、制約、スコープ |
| ADR | 決定とその理由 |
| design doc | 実現方法、現時点の設計 |
| runbook | 運用作業の手順 |
| postmortem | 起きた障害の事後分析 |

- 他のドキュメント種別に属する内容は書かない
- リンクは表で自分より上にあるドキュメントへだけ張る
    - 逆方向へは張らない
    - 同じ種別どうしのリンクは張ってよい

## feature とは

Screaming Architecture における機能の凝集単位。
フロントエンドからバックエンドまでを横断する、機能で切った単位を指す。
システム横断のドキュメントは、特定の feature に閉じない内容を扱う。

## 出力先

- システム横断: `/docs/researches/` 以下
- feature 固有: `/docs/features/<feature-name>/researches/` 以下

`/docs/features/` が存在しないリポジトリーでは、出力先をユーザーに確認する。

ファイル名は `kebab-case-title.md`。 連番や日付は付けない。

## テンプレート

`${CLAUDE_SKILL_DIR}/references/research.md` を使う。

## 規則

- 1 ファイルに 1 つの調査テーマを書く
- 確認できた事実だけを書く
    - 評価、示唆、意見は書かない
- 出典は本文の該当語句にインラインリンクを張る
- 情報が不足しているセクションは「TBD」と記載する
- 現在の実装状況を判断に使わない
- ドキュメントに実装状況を書かない
- その他はテンプレートのセクション構成と説明に従う

## 手順

1. 生成 / 更新対象の research がシステム横断か feature 固有かを判断する
    - 単一の feature に閉じる内容なら feature 固有、複数 feature やシステム基盤に関わるならシステム横断とする
    - `/docs/features/` 以下のディレクトリー一覧を feature の候補として参照する
    - 不明ならユーザーに確認する
2. テンプレートを読み込む
3. 出力先ディレクトリーの既存 research を確認する
    - 更新なら該当ファイルを読み込み、更新対象とする
    - 新規なら同じ調査テーマを扱う既存 research がないかを確認する
4. ユーザーの要求と既存情報をもとに、規則に従って research を作成、更新する
    - 「TBD」と記載したセクションはユーザーに確認する
5. この research へリンクしている PRD、ADR、design doc を探し、research の内容がそれらの前提と矛盾すればユーザーに報告する
6. plan-tasks スキルで作成したタスクリスト Artifact が本作業に存在する場合、research の変更に伴う更新が必要かを確認し、必要であれば更新する
7. GitHub Issues を確認し、research の変更に伴い Issues の追加、変更、削除が必要であればユーザーに進言する
8. 出力先に research を書き出す
9. Task ツールで `skill-adherence:skill-adherence-checker` sub-agent を起動し、`dev-docs:research` と書き出したファイルのパスを渡して Skill 違反を検査させる
    - この sub-agent が使えない環境ではこの手順を省く
    - 報告された違反を research に反映する
