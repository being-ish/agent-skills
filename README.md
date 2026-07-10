# agent-skills

我々のエージェントスキルを Claude Code のプラグインマーケットプレイス形式で配布するリポジトリー。

## インストール

Claude Code で次を実行する。

```
/plugin marketplace add being-ish/agent-skills
/plugin install <plugin-name>@being-ish
```

## プラグインの追加手順

### ディレクトリーを作成する

[プラグイン開発ガイド](https://code.claude.com/docs/en/plugins)に従い、`plugins/<plugin-name>/` を次の構造で作成する。

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    └── <skill-name>/
        └── SKILL.md
```

### plugin.json を書く

[plugin.json](https://code.claude.com/docs/en/plugins-reference) に最低限の情報を書く。

| フィールド    | 内容                                                                    |
|---------------|-------------------------------------------------------------------------|
| `name`        | 端的に挙動を表す名前とする                                              |
| `description` | 何をするかの概要を書く                                                  |
| `version`     | 更新はバンプしたときだけ配られるので、リリース時にバンプを忘れないこと  |


```json
{
  "name": "<plugin-name>",
  "description": "プラグインの説明",
  "version": "1.0.0"
}
```

### marketplace.json にエントリーを追加する

[marketplace.json](https://code.claude.com/docs/en/plugin-marketplaces) の `plugins` 配列にエントリーを追加する。

| フィールド    | 内容                                                                |
|---------------|---------------------------------------------------------------------|
| `name`        | plugin.json の `name` と一致させる。違うとユーザーの混乱の元になる  |
| `source`      | プロジェクトルートからの相対パス                                    |
| `description` | 導入する利点を書く。インストール前の一覧で読まれる                  |
| `version`     | plugin.json の値を正とするので、ここには書かない                    |

```json
{
  "name": "<plugin-name>",
  "source": "<plugin-name>",
  "description": "プラグインの説明"
}
```
