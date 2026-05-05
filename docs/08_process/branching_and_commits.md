# ブランチ戦略・コミット規約

## 1. 目的

Git 上での **ブランチ運用とコミットメッセージ** を統一する。Claude Code と人間の双方が、過去の変更履歴を **意味的に追跡可能** にする。

## 2. ブランチ戦略

### 2.1 主要ブランチ
- `main`: 常にデプロイ可能。直接 push 禁止。タグでリリース
- `develop`(任意): 統合用。プロジェクト方針で採否(小規模は `main` 直行も可)
- `release/<version>`(任意): リリース固定化用、ホットフィックス分岐元

### 2.2 作業ブランチ
- 命名: `<type>/<short-desc>`
- type: `feat` / `fix` / `refactor` / `chore` / `docs` / `test` / `perf` / `build` / `ci`
- short-desc: `kebab-case`、3〜5 語
- 例: `feat/boss-spider-cave`, `fix/save-corruption`, `chore/upgrade-godot`

### 2.3 ブランチ寿命
- 作業ブランチは **短命**(目安: 数日)が望ましい
- 長命化は分解不足のサイン → `task_decomposition_policy.md`

## 3. コミットメッセージ(Conventional Commits 準拠)

```
<type>(<scope>): <subject>

<body 任意>

<footer 任意>
```

### 3.1 type
- `feat`: 機能追加
- `fix`: 不具合修正
- `refactor`: 機能変更なしの改善
- `chore`: 設定・依存・周辺
- `docs`: ドキュメント
- `test`: テストのみ
- `perf`: 性能改善
- `build`: ビルド/パッケージ
- `ci`: CI 設定
- `revert`: 取消

### 3.2 scope(任意だが推奨)
- 変更領域を 1〜2 単語で(`player`, `boss`, `shader`, `assets`, `ci`, `docs/02_services`)

### 3.3 subject
- 命令形・現在形(「add」「fix」「rename」)
- 末尾ピリオドなし
- 50 文字以内が目安、最大 72

### 3.4 body
- 何をなぜ(How はコード)
- 1 行 72 文字目安、複数段落可

### 3.5 footer
- `Refs: #123`, `Closes: #45`
- 破壊的変更: `BREAKING CHANGE: ...`

### 3.6 例
```
feat(boss): add spider boss state machine

Adds idle/charge/attack/recover states using AnimationTree.
Uses navigation mesh for chase movement.

Refs: #142
```

## 4. コミット粒度

- **意味単位** で 1 コミット
- 「半端な状態」を残さない(各コミットでビルドが通る)
- 大規模変更は段階分けして連続コミット

### 4.1 1 コミットに含めて良い変更例
- 機能追加 + その単体テスト
- リネーム + 参照箇所の一括更新
- 規約準拠の自動修正

### 4.2 分けるべき変更例
- 機能追加と無関係なリファクタ
- 仕様変更と命名変更
- 複数機能の同時追加

## 5. PR 単位

- 1 PR = 1 機能 / 1 変更目的
- 大規模機能はサブ PR に分割
- レビュー難度を上げない

## 6. マージ戦略

| 戦略 | いつ |
|---|---|
| Squash merge | 通常の機能 PR(履歴を簡潔に) |
| Merge commit | リリースブランチへの統合 |
| Rebase merge | 線形履歴を強く維持したい場合 |

プロジェクトで一つを基本戦略に決め、必要に応じ例外を使う。

## 7. リベース vs マージ

- 個人作業ブランチでの履歴整理: rebase 可
- main / 共有ブランチへの取り込み: マージ戦略に従う
- 公開済コミットの履歴改変は避ける(やる場合は影響者に通告)

## 8. タグ

- リリースは `vMAJOR.MINOR.PATCH` 形式
- 必要なら `-rc.N`, `-beta.N` 接尾
- タグは push 後に CI が release ワークフロー起動

## 9. ブランチ保護

- `main` 直 push 禁止
- 必須レビュアと必須 CI を設定
- 強制 push 禁止
- 重要 Environments は Required Reviewers

## 10. Claude Code の振る舞い

- ブランチ作成は規約に従い自動化可
- コミットメッセージは Conventional Commits を生成
- 共著表記(Co-Authored-By)は CI/プロジェクト方針に従う
- `--no-verify` / `--force` は **明示同意なしに使わない**

## 11. アンチパターン

- 巨大「とりあえず」コミット
- 意味のない `wip`, `update`, `fix typo`(本当に typo なら OK)
- ブランチに無関係な変更を混ぜる
- 公開 main への強制 push
- リベース後の履歴が崩壊している

## 12. 参照
- レビュー: `review_procedure.md`
- 命名: `04_standards/naming_conventions.md`
- 完了定義: `definition_of_ready_done.md`
