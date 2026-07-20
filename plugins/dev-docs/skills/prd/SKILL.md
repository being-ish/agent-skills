---
name: prd
description: PRD を生成・更新する。要件定義に使う。
---

# PRD 生成・更新

PRD: Product Requirements Document は何を作るか・なぜ作るかを定義する。

## ドキュメント間の関係

| ドキュメント | 書くもの |
|---|---|
| PRD | 要件、制約、スコープ |
| ADR | 決定とその理由 |
| design doc | 実現方法、現時点の設計 |

- 他のドキュメント種別に属する内容は書かない
- 参照方向は PRD が上流、ADR / design doc が下流
- リンクは下流から上流へのみ張る
    - PRD から ADR / design doc へはリンクしない

## feature とは

Screaming Architecture における機能の凝集単位。
フロントエンドからバックエンドまでを横断する、機能で切った単位を指す。
システム全体のドキュメントは、特定の feature に閉じない内容を扱う。

## 出力先

- システム全体: `/docs/PRD.md`
- feature 固有: `/docs/features/<feature-name>/PRD.md`

`/docs/features/` が存在しないリポジトリーでは、出力先をユーザーに確認する。

## テンプレート

- システム全体: `${CLAUDE_SKILL_DIR}/references/system-prd.md`
- feature 固有: `${CLAUDE_SKILL_DIR}/references/feature-prd.md`

## 手順

1. 生成 / 更新対象の PRD がシステム全体か feature 固有かを判断する
    - 単一の feature に閉じる内容なら feature 固有、複数 feature やシステム基盤に関わるならシステム全体とする
    - `/docs/features/` 以下のディレクトリー一覧を feature の候補として参照する
    - 不明ならユーザーに確認する
2. 該当するテンプレートを読み込む
3. 既存の PRD ファイルがあれば読み込み、更新対象とする
4. ユーザーの要求と既存情報をもとに PRD を作成・更新する
    - 情報が不足しているセクションは「TBD」と記載し、ユーザーに確認する
    - その他はテンプレートのセクション構成に従う
5. Design Doc や ADR など関連ドキュメントが存在する場合、整合性をチェックし、矛盾があればユーザーに報告する
6. GitHub Issues を確認し、PRD の変更に伴い Issues の追加・変更・削除が必要であればユーザーに進言する
7. 出力先に PRD を書き出す
