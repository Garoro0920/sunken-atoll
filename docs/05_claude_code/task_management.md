# タスク管理

## 1. 目的

Claude Code が扱う作業単位の **管理規律** を定め、進捗と責務の見える化を保つ。

## 2. タスクの種類

| 種類 | 道具 | 寿命 |
|---|---|---|
| セッション内サブタスク | Claude Code 内 TaskCreate / TaskList | 1 セッション |
| 仕様 / エピック | `specs/` 配下 + GitHub Issue | 数日〜数ヶ月 |
| ロードマップ | GitHub Projects / マイルストーン | 数ヶ月〜年単位 |

## 3. セッション内タスクの規律

1. **3 ステップを超える作業は必ずタスク化**
2. 着手前に `in_progress` に更新
3. 完了直後に `completed` に更新
4. 失敗・ブロックは `in_progress` のまま、ブロック理由をコメント
5. 古いタスクや無関係タスクは `deleted` で整理

## 4. タスクの粒度

- 1 タスク = 1 つの **動詞 + 目的語**(例: 「ボス攻撃モーションを生成」)
- 完了/未完了が二値で判定可能
- 30 分〜2 時間で完了する規模を目安

## 5. タスク説明の書き方

```
subject: ボス攻撃モーションを生成
description:
  - 入力: specs/features/boss_intro.md の "attack motions"
  - 必要モーション: swing_horizontal, swing_vertical, slam
  - サービス: DeepMotion(text-to-motion)
  - 出力: assets/raw/animations/boss_<id>.glb
  - 完了条件: AnimationLibrary に取込・命名規約準拠・シナリオテスト通過
```

## 6. 依存関係

- `addBlockedBy` / `addBlocks` で順序関係を表現
- 並列可能なタスクは依存を作らない
- 巨大依存グラフは仕様を分割するシグナル

## 7. 並列実行

- 独立タスクは複数同時に進める(Claude Code の並列 tool 呼出を活用)
- ただし同じファイル群を触る並列は避ける(コンフリクトの温床)

## 8. ブロック・例外

- 外部要因でブロックされた場合は **理由と解除条件** をタスクに記録
- 期限がある場合は明記

## 9. 仕様(spec)の管理

- `specs/features/<feature>.md` 1 機能 1 ファイル
- 構造: 目的、ユーザストーリー、要件、非要件、UX 概略、データ構造、テスト観点、リスク、参照
- spec の改訂は履歴を残す(Git)

## 10. GitHub Issue / Projects

- 外部から見える単位は Issue / Projects に集約
- Issue は spec と 1:1 でリンクする(本文に相互参照)
- ラベル: `type/*`, `area/*`, `priority/*`, `status/*`
- Closed 条件は spec の DoD と一致

## 11. ロードマップ

- 四半期 / マイルストーン単位
- 戦略的優先度を可視化
- Claude Code は週次でロードマップ進捗をサマリ可

## 12. 引継ぎ

- セッション終了時、Claude Code は次の引継メモを残す:
  - 完了タスク要約
  - 未完了タスク + 次の最初の一歩
  - 重要な意思決定とその理由
  - 観察された懸念

## 13. アンチパターン

- 一つのタスクに無関係な複数項目を詰める
- ステータスを更新しないまま進む
- 完了と同義の依頼に対しタスクを立てる(粒度過剰)
- 同義タスクを重複作成
- 失敗時にタスクを `completed` にして隠蔽

## 14. 振り返り

- 大きなマイルストーン後に短い振り返りメモを `pipeline/retrospectives/` に残す
- 何が機能し、何が機能しなかったか、次の改善
- ドキュメント改訂につなげる

## 15. 参照
- 共同開発: `05_claude_code/collaboration_guide.md`
- 指示: `05_claude_code/instruction_protocol.md`
- タスク分解: `05_claude_code/task_decomposition_policy.md`
- エスカレーション: `05_claude_code/escalation_policy.md`
- 完了定義: `08_process/definition_of_ready_done.md`
