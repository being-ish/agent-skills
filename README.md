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

[plugin.json](https://code.claude.com/docs/en/plugins-reference) に最低限の情報を書く。`description` には何をするかの概要を書く。`version` は plugin.json だけに書く。更新はバンプしたときだけ配られるので、リリース時にバンプを忘れない。

```json
{
  "name": "<plugin-name>",
  "description": "プラグインの説明",
  "version": "1.0.0"
}
```

### marketplace.json にエントリーを追加する

[marketplace.json](https://code.claude.com/docs/en/plugin-marketplaces) の `plugins` 配列にエントリーを追加する。`metadata.pluginRoot` が `./plugins` なので `source` はディレクトリー名だけでよい。`description` はインストール前の一覧で読まれるため、導入する利点を書く。`name` は plugin.json と必ず一致させる。食い違うとこちらの名前がインストールや設定のキーに、plugin.json 側の名前がコンポーネントの名前空間に使われて混乱する。`version` はここには書かない。

```json
{
  "name": "<plugin-name>",
  "source": "<plugin-name>",
  "description": "プラグインの説明"
}
```