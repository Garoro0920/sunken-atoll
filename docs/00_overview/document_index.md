# ドキュメント索引

本ドキュメント群の全エントリ一覧と改訂運用ルールを定める。新規追加・改訂・削除を行った際は、本ファイルの該当行を必ず同一 PR 内で更新すること。

## 索引

| ID | パス | 種別 | 目的 |
|---|---|---|---|
| OV-01 | `00_overview/project_charter.md` | 概要 | プロジェクト憲章 |
| OV-02 | `00_overview/glossary.md` | 概要 | 用語集 |
| OV-03 | `00_overview/document_index.md` | 概要 | 本ファイル(索引) |
| AR-01 | `01_architecture/system_architecture.md` | 設計 | システム全体像 |
| AR-02 | `01_architecture/pipeline_topology.md` | 設計 | パイプライン構成 |
| AR-03 | `01_architecture/data_flow.md` | 設計 | データフロー |
| AR-04 | `01_architecture/directory_structure.md` | 設計 | プロジェクトディレクトリ構造 |
| SV-01 | `02_services/service_catalog.md` | サービス | 採用サービス一覧 |
| SV-02 | `02_services/api_integration_guide.md` | サービス | API 統合方針 |
| SV-03 | `02_services/secrets_management.md` | サービス | 認証情報管理 |
| SV-04 | `02_services/version_policy.md` | サービス | バージョン採択方針 |
| SV-05 | `02_services/tripo.md` | サービス | Tripo AI(L1 メッシュ主・L2 テクスチャ主・L4 Auto-Rig) |
| SV-06 | `02_services/meshy.md` | サービス | Meshy AI(L1 メッシュ代替・L2 テクスチャ代替) |
| WF-01 | `03_workflows/asset_generation_workflow.md` | 運用 | アセット生成 |
| WF-02 | `03_workflows/scene_assembly_workflow.md` | 運用 | シーン構築 |
| WF-03 | `03_workflows/testing_workflow.md` | 運用 | テスト |
| WF-04 | `03_workflows/build_release_workflow.md` | 運用 | ビルド・リリース |
| WF-05 | `03_workflows/incident_response_workflow.md` | 運用 | 障害対応 |
| ST-01 | `04_standards/coding_standards.md` | 規約 | コーディング規約 |
| ST-02 | `04_standards/asset_standards.md` | 規約 | アセット規約 |
| ST-03 | `04_standards/scene_standards.md` | 規約 | シーン規約 |
| ST-04 | `04_standards/naming_conventions.md` | 規約 | 命名規約 |
| ST-05 | `04_standards/quality_gates.md` | 規約 | 品質ゲート |
| CC-01 | `05_claude_code/collaboration_guide.md` | 協調 | 共同開発ガイド |
| CC-02 | `05_claude_code/instruction_protocol.md` | 協調 | 指示プロトコル |
| CC-03 | `05_claude_code/dialogue_protocol.md` | 協調 | 対話プロトコル |
| CC-04 | `05_claude_code/task_management.md` | 協調 | タスク管理 |
| CC-05 | `05_claude_code/prompt_templates.md` | 協調 | プロンプトテンプレート |
| CC-06 | `05_claude_code/memory_policy.md` | 協調 | 記憶ポリシー |
| CC-07 | `05_claude_code/escalation_policy.md` | 協調 | エスカレーション基準 |
| CC-08 | `05_claude_code/prompt_engineering_guide.md` | 協調 | プロンプト設計ガイド |
| CC-09 | `05_claude_code/task_decomposition_policy.md` | 協調 | タスク分解ポリシー |
| CC-10 | `05_claude_code/session_protocol.md` | 協調 | セッションプロトコル |
| CC-11 | `05_claude_code/context_management.md` | 協調 | コンテキスト管理 |
| CC-12 | `05_claude_code/agent_orchestration.md` | 協調 | サブエージェント運用 |
| CC-13 | `05_claude_code/failure_playbook.md` | 協調 | 失敗対応プレイブック |
| OP-01 | `06_operations/ci_cd_pipeline.md` | 運用 | CI/CD |
| OP-02 | `06_operations/monitoring.md` | 運用 | 監視 |
| OP-03 | `06_operations/localization.md` | 運用 | ローカライズ |
| OP-04 | `06_operations/distribution.md` | 運用 | 配布 |
| GV-01 | `07_governance/licensing.md` | 統治 | ライセンス管理 |
| GV-02 | `07_governance/ip_policy.md` | 統治 | 知的財産方針 |
| GV-03 | `07_governance/ai_ethics.md` | 統治 | AI 倫理 |
| PR-01 | `08_process/development_flow.md` | プロセス | 開発フロー定義 |
| PR-02 | `08_process/review_procedure.md` | プロセス | レビュー手順 |
| PR-03 | `08_process/branching_and_commits.md` | プロセス | ブランチ戦略・コミット規約 |
| PR-04 | `08_process/definition_of_ready_done.md` | プロセス | Definition of Ready / Done |
| PR-05 | `08_process/decision_log_protocol.md` | プロセス | 意思決定ログ(ADR/RFC) |

## 改訂運用ルール

1. 1 PR で改訂するドキュメントは関連する範囲に限定する
2. 重要度の高い改訂(憲章・規約・品質ゲート)は人間の最終承認を必須とする
3. 改訂後は CI による Markdown リンタ・リンク切れ検査を通過させる
4. ドキュメント間の相互参照は壊れていないかを必ず確認する
5. 詳細な意思決定経緯は `08_process/decision_log_protocol.md` に従い別途記録する(本索引には変更履歴を残さない)
