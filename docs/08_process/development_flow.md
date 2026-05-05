# 開発フロー定義

## 1. 目的

要求が起票されてから本番リリースに至るまでの **開発工程の標準フロー** を定義する。Claude Code が各段階でどう振る舞うかも示す。

## 2. フロー全景

```
[Idea] → [Spec] → [Ready] → [Decompose] → [Implement] → [Review]
   → [Verify] → [Integrate] → [Build] → [Stage] → [Release] → [Operate] → (戻り)
```

## 3. 各段階

### 3.1 Idea(着想)
- 起点: PO / CD / オペレータの発案、ユーザフィードバック、運用指標
- 出力: 1 行のアイデアメモ(GitHub Issue 起票が標準)
- Claude Code: 過去類似アイデアの引当、リスク予兆の指摘

### 3.2 Spec(仕様化)
- 出力: `specs/features/<feature>.md`
- 構成: 目的、ユーザストーリー、要件、非要件、UX、データ、テスト観点、リスク
- Claude Code: ドラフト支援、矛盾検出、抜け漏れ指摘
- 完了基準: Definition of Ready(`08_process/definition_of_ready_done.md`)

### 3.3 Ready(着手準備)
- 仕様の合意、依存解決、必要アセット定義
- Claude Code: 必要アセット一覧と生成計画を提示
- ゲート: Definition of Ready 合格

### 3.4 Decompose(分解)
- spec → タスク分解(`05_claude_code/task_decomposition_policy.md`)
- 並列可否、依存関係、優先度
- 出力: TaskList 反映

### 3.5 Implement(実装)
- ブランチ作成(`08_process/branching_and_commits.md`)
- コード/シーン/アセット生成と配置
- 実装中も小コミット推奨
- Claude Code: 規約遵守、テスト同時整備

### 3.6 Review(レビュー)
- 一次レビュー: Claude Code(`08_process/review_procedure.md`)
- 必要に応じ人間レビュー(規約逸脱・大型変更・規制領域)
- 修正反映 → 再レビュー

### 3.7 Verify(検証)
- 単体・統合・シナリオ・視覚回帰・パフォーマンス
- 視覚は Vision で意味的判定
- ゲート: G1 / G2(`04_standards/quality_gates.md`)

### 3.8 Integrate(統合)
- main へのマージ
- マージ後の自動 nightly 実行
- 失敗発生時はホットフィックス or revert

### 3.9 Build(ビルド)
- リリースタグ → CI でマルチプラットフォームビルド
- ゲート: G3
- アーティファクトを長期保管

### 3.10 Stage(プレリリース)
- itch.io beta / Steam beta / TestFlight / Play 内部
- 関係者プレイ + 監視ダッシュボード初期確認
- フィードバックを起票へ戻す

### 3.11 Release(本番)
- 人間承認(PO)
- ストア審査
- 公開
- ゲート: G4

### 3.12 Operate(運用)
- 監視、ユーザサポート、インシデント対応
- 改善案 / バグ報告は Issue に起票し Idea へ戻す
- ゲート: G5(継続的)

## 4. 並走の許容

- 複数機能が並走可能。ブランチ分離 + 触る範囲分離で回避
- 共通基盤の改修は予告 + 短期で取り込む
- スプリント単位で同期(任意のリズム、プロジェクト固有)

## 5. リズム(目安)

| サイクル | 期間 | 内容 |
|---|---|---|
| デイリー | 1 日 | 進捗共有、ブロッカー解消 |
| スプリント | 1〜2 週 | 計画・実装・振り返り |
| マイルストーン | 1〜数ヶ月 | リリースの粒度 |
| クォータリー | 3 ヶ月 | ロードマップ見直し |

実際の周期はプロジェクトで決定。

## 6. 役割の典型分担

| 段階 | 主担当 |
|---|---|
| Idea / Spec | 人間 + Claude Code(支援) |
| Ready / Decompose | Claude Code(草案)+ 人間承認 |
| Implement / Verify | Claude Code |
| Review | Claude Code(一次)+ 人間(必要時) |
| Build | Claude Code(自動)|
| Release | 人間承認 + Claude Code(実行) |
| Operate | Claude Code(初期トリアージ)+ 人間 |

## 7. 詰まったときの戻り

- Verify で失敗 → Implement 戻し
- Stage で問題 → Build 戻し or Implement 戻し
- 仕様矛盾発覚 → Spec 改訂、影響タスク再分解
- 法務/倫理問題 → 即時停止、エスカレーション

## 8. 文書連動

- どの段階でどの docs を更新するかを決めておく(`document_index.md` 参照)
- 規約変更は `04_standards/`、API 採用変更は `02_services/`、運用変更は `06_operations/`

## 9. メトリクス

- リードタイム(Idea → Release)
- サイクルタイム(Implement → Verify 緑)
- 変更失敗率(リリース後ロールバック)
- 品質指標(クラッシュ率、バグ件数)

これらは継続的に観察し、フローの改善材料にする。

## 10. 参照
- 仕様起票: `05_claude_code/instruction_protocol.md`
- 分解: `05_claude_code/task_decomposition_policy.md`
- レビュー: `08_process/review_procedure.md`
- 完了定義: `08_process/definition_of_ready_done.md`
- ブランチ: `08_process/branching_and_commits.md`
