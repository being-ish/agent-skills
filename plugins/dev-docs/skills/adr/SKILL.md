---
name: adr
description: ADR を生成・更新する。方針決定、技術選定、設計判断時の経緯の記録に使う
---

# ADR 生成・更新

ADR: Architecture Decision Record は方針決定、技術選定、設計判断の記録。

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
システム横断のドキュメントは、特定の feature に閉じない内容を扱う。

## 出力先

- システム横断: `/docs/adr/` 以下
- feature 固有: `/docs/features/<feature-name>/adr/` 以下

`/docs/features/` が存在しないリポジトリーでは、出力先をユーザーに確認する。

ファイル名は `NNNN-kebab-case-title.md`。 NNNN は 0001 からの連番。

## テンプレート

- `${CLAUDE_SKILL_DIR}/references/adr.md`

## 手順

1. 生成 / 更新対象の ADR がシステム横断か feature 固有かを判断する
   - 単一の feature に閉じる内容なら feature 固有、複数 feature やシステム基盤に関わるならシステム横断とする
   - `/docs/features/` 以下のディレクトリー一覧を feature の候補として参照する
   - 不明ならユーザーに確認する
2. テンプレートを読み込む
3. 出力先ディレクトリの既存 ADR を確認し、次の連番を決定する
4. ユーザーの要求をもとに ADR を作成する
    - 情報が不足しているセクションは「TBD」と記載し、ユーザーに確認する
    - 新規作成時のステータスは「有効」とする
    - 生成 / 更新時は既存 ADR に廃止されるものがないかチェックし、該当があれば旧 ADR のステータスを更新する
    - その他はテンプレートのセクション構成に従う
5. PRD や design doc など関連ドキュメントが存在する場合、整合性をチェックし、矛盾があればユーザーに報告する
6. GitHub Issues を確認し、ADR の変更に伴い Issues の追加・変更・削除が必要であればユーザーに進言する
7. 出力先に ADR を書き出す
