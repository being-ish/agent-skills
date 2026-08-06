---
name: design-doc
description: design doc を生成、更新する。大まかなアーキテクチャー設計やどう作るかの定義に使う
---

# design doc の生成と更新

design doc はどう作るか、現時点での設計を記載する。

## ドキュメント間の関係

各ドキュメントは、表で自分より上にあるドキュメントを前提として書く。

| ドキュメント | 書くもの |
|---|---|
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

| 対象 | 出力先 |
|---|---|
| システム全体 | `/docs/design-doc.md` |
| feature 固有 | `/docs/features/<feature-name>/design-doc.md` |

`/docs/features/` が存在しないリポジトリーでは、出力先をユーザーに確認する。

## テンプレート

| 対象 | テンプレート |
|---|---|
| システム全体 | `${CLAUDE_SKILL_DIR}/references/system-design-doc.md` |
| feature 固有 | `${CLAUDE_SKILL_DIR}/references/feature-design-doc.md` |

## 手順

1. 生成 / 更新対象の design doc がシステム全体か feature 固有かを判断する
    - 単一の feature に閉じる内容なら feature 固有、複数 feature やシステム基盤に関わるならシステム全体とする
    - `/docs/features/` 以下のディレクトリー一覧を feature の候補として参照する
    - 不明ならユーザーに確認する
2. 該当するテンプレートを読み込む
3. 既存の design doc があれば読み込み、更新対象とする
4. ユーザーの要求と既存情報をもとに design doc を作成、更新する
    - 情報が不足しているセクションは「TBD」と記載し、ユーザーに確認する
    - feature 固有のものでシステム全体のものと差分がない場合は、システム全体 design doc に準ずる旨を明記する
    - その他はテンプレートのセクション構成に従う
5. PRD や ADR など関連ドキュメントが存在する場合、整合性をチェックし、矛盾があればユーザーに報告する
6. plan-tasks スキルで作成したタスクリスト Artifact が本作業に存在する場合、design doc の変更に伴う更新が必要かを確認し、必要であれば更新する
7. GitHub Issues を確認し、design doc の変更に伴い Issues の追加、変更、削除が必要であればユーザーに進言する
8. 出力先に design doc を書き出す
