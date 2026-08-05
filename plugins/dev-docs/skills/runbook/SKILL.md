---
name: runbook
description: runbook を生成、更新する。定常メンテナンスの手順化、障害対応手順の記録に使う
---

# runbook の生成と更新

runbook は運用作業の手順を記載する。

## ドキュメント間の関係

| ドキュメント | 書くもの |
|---|---|
| PRD | 要件、制約、スコープ |
| ADR | 決定とその理由 |
| design doc | 実現方法、現時点の設計 |
| runbook | 運用作業の手順 |

- 他のドキュメント種別に属する内容は書かない
    - 設計の背景や理由は書かず、design doc / ADR へリンクする
- 参照方向は PRD が上流、ADR / design doc / runbook が下流
- リンクは下流から上流へのみ張る
    - PRD から ADR / design doc / runbook へはリンクしない

## feature とは

Screaming Architecture における機能の凝集単位。
フロントエンドからバックエンドまでを横断する、機能で切った単位を指す。
システム全体のドキュメントは、特定の feature に閉じない内容を扱う。

## runbook の種類

| 種類 | 書くもの |
|---|---|
| `maintenance` | 定常メンテナンス、計画的に繰り返す運用作業の手順 |
| `incident` | 障害対応、アラートや症状を起点とした緊急時の手順 |

`incident` の runbook は 1 ファイルに 1 症状とし、対応中に読む範囲を 1 つのオペレーションに絞る。
症状からの逆引きは `incident/README.md` の索引が担う。

## 出力先

- システム全体: `/docs/runbooks/<種類>/` 以下
- feature 固有: `/docs/features/<feature-name>/runbooks/<種類>/` 以下

`/docs/features/` が存在しないリポジトリーでは、出力先をユーザーに確認する。

内容から引けるよう、ファイル名は扱う作業や症状がわかるものとする。形式は kebab-case。

緊急時に迅速に対応できるよう逆引きできるようにする。そのために `incident` の索引を `incident/README.md` に作る。

## テンプレート

| 種類 | テンプレート |
|---|---|
| `maintenance` | `${CLAUDE_SKILL_DIR}/references/maintenance-runbook.md` |
| `incident` | `${CLAUDE_SKILL_DIR}/references/incident-runbook.md` |
| `incident` の索引 | `${CLAUDE_SKILL_DIR}/references/incident-index.md` |

## 手順

1. 生成 / 更新対象の runbook がシステム全体か feature 固有かを判断する
    - 単一の feature に閉じる内容なら feature 固有、複数 feature やシステム基盤に関わるならシステム全体とする
    - `/docs/features/` 以下のディレクトリー一覧を feature の候補として参照する
    - 不明ならユーザーに確認する
2. `maintenance` か `incident` かを判断する
    - 計画的に繰り返す作業なら `maintenance`、アラートや障害を起点とするなら `incident` とする
    - 不明ならユーザーに確認する
3. 該当するテンプレートを読み込む
4. 出力先ディレクトリーの既存 runbook を確認する
    - 更新なら該当ファイルを読み込み、更新対象とする
    - 新規なら内容が重複する既存 runbook がないかを確認する
5. ユーザーの要求と既存情報をもとに runbook を作成、更新する
    - 1 ファイルに 1 つの作業または 1 つの症状
    - 実行するコマンドは省略せずそのまま書く
    - 各手順には期待する結果と、失敗したときの分岐を書く
    - 判断を要する箇所は判断基準を明記する
    - 情報が不足しているセクションは「TBD」と記載し、ユーザーに確認する
    - その他はテンプレートのセクション構成に従う
6. `incident` の runbook を作成、更新した場合は `incident/README.md` の索引を更新する
    - 索引がなければ索引テンプレートから作成する
7. PRD や design doc、ADR など関連ドキュメントが存在する場合、整合性をチェックし、矛盾があればユーザーに報告する
8. plan-tasks スキルで作成したタスクリスト Artifact が本作業に存在する場合、runbook の変更に伴う更新が必要かを確認し、必要であれば更新する
9. GitHub Issues を確認し、runbook の変更に伴い Issues の追加、変更、削除が必要であればユーザーに進言する
10. 出力先に runbook を書き出す
