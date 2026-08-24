---
name: testing-style-vitest
description: Vitest でのテストの書き方の指針。TypeScript や JavaScript のテストを書く、変更する前に必ず読む。vi.mock でモックする対象の選び方と importOriginal の使い方を定めた指針
user-invocable: false
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.mjs"
  - "**/*.cjs"
---

Vitest でテストを書くときの指針。言語非依存の規則は `testing-style:testing-style` にある。

ここに記載のない事柄はコードベースの既存テストに合わせること。

## 規則

### モック

#### 対象

`vi.mock` はビルド時にモジュール先頭へ hoisting される。in-source testing で `vi.mock("node:fs/promises")` のように共有モジュールをモックすると、そのファイルを import する別ファイルのテストにもモックが適用されてしまう。

- 自分が import しているモジュールだけを `vi.mock` する
- 依存の依存を推移的にモックしない
- モックの向こう側のロジックは、そのモジュール自身の in-source テストで担保する

#### 差し替え方

依存モジュールの定数はそのまま使いたい場合、`importOriginal` を spread して関数だけ `vi.fn()` に差し替える。

```ts
vi.mock("./config", async (importOriginal) => ({
  ...(await importOriginal<typeof import("./config")>()),
  load: vi.fn(),
}));
```

## 手順

1. 規則に従ってテストを書く
2. Task ツールで `skill-adherence:skill-adherence-checker` sub-agent を起動し規則違反をチェックさせる
    - この sub-agent が使えない環境ではこの検査を省く
    - 次を渡す
        - `testing-style:testing-style-vitest`
        - 変更したファイルのパス
3. 報告された違反を修正する
    - 修正がさらに規則に違反していないか注意する
