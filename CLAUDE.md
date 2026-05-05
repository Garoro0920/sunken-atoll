# CLAUDE.md

本ファイルは Claude Code がプロジェクト操作時に **最初に必ず参照** する永続知識である。本プロジェクトは Godot 4 を基盤とし、Claude Code を主オーケストレータとする 3D ゲーム開発パイプラインのテンプレートである。

## 0. 行動規範(最優先)

1. **`docs/` 配下のドキュメント群が Single Source of Truth** である。本ファイルとの矛盾が生じた場合、`docs/` を優先する
2. **特定の外部サービス・SDK・ライブラリのバージョン番号を本ファイルや `docs/` に書き込まない**。バージョンは `docs/02_services/version_policy.md` のマトリクスでのみ管理する
3. シークレットを対話・コミット・ログに残さない(`docs/02_services/secrets_management.md`)
4. 重大決定は `docs/05_claude_code/escalation_policy.md` に従い人間に判断を委ねる

## 1. セッション開始時に必ず行うこと

1. 本ファイル(`CLAUDE.md`)を読む
2. `docs/README.md` の索引で全体像を把握する
3. 関連ドキュメントを参照する(目的に応じ最低限):
   - 共同開発: `docs/05_claude_code/collaboration_guide.md`
   - 該当ワークフロー: `docs/03_workflows/`
   - 該当規約: `docs/04_standards/`
4. `TaskList` で未完了タスクを確認する
5. `pipeline/decisions/` の直近メモがあれば読み、文脈を再構成する

## 2. プロジェクト概要

- 基盤: Godot 4(具体バージョンは `docs/02_services/version_policy.md`)
- スタイル: 3D ゲーム
- パイプライン: API 駆動の生成系 + MCP 駆動の制御 + CI 駆動の検証
- 役割: 人間が方向性を決め、Claude Code が実装・統合・検証を主導
- 詳細: `docs/00_overview/project_charter.md`

## 3. 主要アクションの参照先

| 何をしたい | 読むべきドキュメント |
|---|---|
| アセットを生成して取り込む | `docs/03_workflows/asset_generation_workflow.md` |
| シーンを構築する | `docs/03_workflows/scene_assembly_workflow.md` |
| テストを実装/実行する | `docs/03_workflows/testing_workflow.md` |
| ビルド/配布する | `docs/03_workflows/build_release_workflow.md` |
| 障害に対応する | `docs/03_workflows/incident_response_workflow.md` |
| API を統合する | `docs/02_services/api_integration_guide.md` |
| シークレットを扱う | `docs/02_services/secrets_management.md` |
| プロンプトを書く / 設計する | `docs/05_claude_code/prompt_templates.md` / `docs/05_claude_code/prompt_engineering_guide.md` |
| タスクを分解する | `docs/05_claude_code/task_decomposition_policy.md` |
| セッションを開始 / 終了する | `docs/05_claude_code/session_protocol.md` |
| 文脈を節約する / 長期化を防ぐ | `docs/05_claude_code/context_management.md` |
| サブエージェントを使う | `docs/05_claude_code/agent_orchestration.md` |
| 失敗時の典型対応 | `docs/05_claude_code/failure_playbook.md` |
| 人間に判断を仰ぐ | `docs/05_claude_code/escalation_policy.md` |
| 全体の開発フロー | `docs/08_process/development_flow.md` |
| レビューする / される | `docs/08_process/review_procedure.md` |
| ブランチ・コミット・PR | `docs/08_process/branching_and_commits.md` |
| 着手 / 完了の判定 | `docs/08_process/definition_of_ready_done.md` |
| 意思決定を記録する | `docs/08_process/decision_log_protocol.md` |

## 4. 規約サマリ(詳細は docs 参照)

- ファイル命名: `snake_case`、クラス: `PascalCase`、定数: `SCREAMING_SNAKE`
- GDScript は型ヒント必須、`class_name` 必須
- アセットは GLB(glTF 2.0)を第一推奨
- すべての生成物にメタデータ JSON を残す
- すべての変更は PR 経由、品質ゲート必須
- バージョン情報は本ファイルや `docs/` に書かない

## 5. 自動化の境界

- 通常作業(編集・テスト・規約準拠の修正)は Claude Code が自動で進めてよい
- 配布、依存追加、API 切替、ライセンス影響、シークレット改訂、ベースライン更新は **人間承認**
- 詳細: `docs/05_claude_code/collaboration_guide.md` 「自動化と承認の境界」

## 6. ドキュメント変更の責務

- コード変更で規約・ワークフローに影響が出る場合、**ドキュメントを先に更新する**
- 索引(`docs/00_overview/document_index.md`)と整合させる
- 重要な意思決定は `docs/08_process/decision_log_protocol.md` に従い別途記録する

## 7. 出力スタイル

- 短く、的確に、根拠を添えて
- 不要な絵文字・装飾は避ける
- 進捗は節目で 1 文、完了報告は 1〜2 文
- 詳細は `docs/05_claude_code/dialogue_protocol.md`

## 8. 禁止事項(再掲)

- バージョン番号を本ファイル・`docs/` に記載
- シークレットを対話・コミット・ログに残す
- 規約違反の自動マージ
- 範囲外への踏み込み(指示の範囲を勝手に拡大)
- 失敗を隠した完了宣言
- 人間承認が必要な行為の独断実行

## 9. 補助情報

本テンプレートを新規プロジェクトに適用する際は、最初に次を実施する:
1. `docs/02_services/version_policy.md` のバージョンマトリクスを埋める
2. `docs/04_standards/quality_gates.md` の閾値マトリクスを埋める
3. `docs/00_overview/project_charter.md` のスコープと成功基準を該当プロジェクト向けに調整する

これらが完了するまで、本格作業は開始しない。

## 10. 困ったとき

- ドキュメントに該当があれば従う
- 該当がないが軽微なら推奨を示して進める
- 該当がなく重大なら **エスカレーション**
