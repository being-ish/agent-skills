# agent-skills

我々のエージェントスキルを Claude Code のプラグインマーケットプレイス形式で配布するリポジトリー。

## インストール

Claude Code で以下を実行する。

```
/plugin marketplace add being-ish/agent-skills
/plugin install <plugin-name>@being-ish
```

## プラグインの追加手順

1. [プラグイン開発ガイド](https://code.claude.com/docs/en/plugins)に従い、`plugins/<plugin-name>/` を以下の構造で作成する

   ```
   plugins/<plugin-name>/
   ├── .claude-plugin/
   │   └── plugin.json
   └── skills/
       └── <skill-name>/
           └── SKILL.md
   ```

2. [plugin.json](https://code.claude.com/docs/en/plugins-reference) に最低限の情報を書く

   ```json
   {
     "name": "<plugin-name>",
     "description": "プラグインの説明",
     "version": "0.1.0"
   }
   ```

3. [marketplace.json](https://code.claude.com/docs/en/plugin-marketplaces) の `plugins` 配列にエントリーを追加する。`metadata.pluginRoot` が `./plugins` なので `source` はディレクトリー名だけでよい

   ```json
   {
     "name": "<plugin-name>",
     "source": "<plugin-name>",
     "description": "プラグインの説明"
   }
   ```
