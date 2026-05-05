# プロジェクトドキュメント索引

本ディレクトリは、**Godot 4 を基盤とし、Claude Code を主オーケストレータとする 3D ゲーム開発プロジェクト** に必要となる設計・運用・ワークフロー・協調作業のすべてを規定する公式ドキュメント群です。

本ドキュメント群はテンプレートとして再利用されることを前提に設計されており、特定の外部サービス・SDK・ライブラリの **バージョン番号は意図的に記載していません**。バージョンは本プロジェクト開始時点で別途調査し、`docs/02_services/version_policy.md` の手順に従って固定します。

---

## 利用方法

1. プロジェクト開始時、まず `00_overview/project_charter.md` を読み、目的・スコープ・成功基準を確認する
2. 続いて `05_claude_code/collaboration_guide.md` を読み、Claude Code との協調原則を理解する
3. 各セクションは独立して参照可能だが、**読了順序は番号順を推奨**する
4. 変更が発生した場合は該当ドキュメントを更新し、必要に応じ `00_overview/document_index.md` の索引行を整える

---

## ディレクトリ構成

| 区分 | パス | 内容 |
|---|---|---|
| 概要 | `00_overview/` | プロジェクト憲章・用語集・ドキュメント索引 |
| アーキテクチャ | `01_architecture/` | システム全体図・パイプライン・データフロー・ディレクトリ構造 |
| 外部サービス | `02_services/` | サービスカタログ・API 統合方針・認証情報管理・バージョン採択 |
| ワークフロー | `03_workflows/` | アセット生成・シーン構築・テスト・ビルド・障害対応 |
| 規約・基準 | `04_standards/` | コーディング・アセット・シーン・命名・品質ゲート |
| Claude Code 協調 | `05_claude_code/` | 共同開発・指示・対話・タスク・プロンプト・記憶・エスカレーション・プロンプト設計・タスク分解・セッション・文脈・サブエージェント・失敗対応 |
| 運用 | `06_operations/` | CI/CD・監視・ローカライズ・配布 |
| ガバナンス | `07_governance/` | ライセンス・知財・AI 倫理 |
| 開発プロセス | `08_process/` | 開発フロー・レビュー・ブランチ/コミット・DoR/DoD・意思決定ログ |

---

## ドキュメント一覧

### 00_overview
- [プロジェクト憲章](00_overview/project_charter.md)
- [用語集](00_overview/glossary.md)
- [ドキュメント索引](00_overview/document_index.md)

### 01_architecture
- [システムアーキテクチャ](01_architecture/system_architecture.md)
- [パイプライントポロジ](01_architecture/pipeline_topology.md)
- [データフロー](01_architecture/data_flow.md)
- [プロジェクトディレクトリ構造](01_architecture/directory_structure.md)

### 02_services
- [サービスカタログ](02_services/service_catalog.md)
- [API 統合ガイド](02_services/api_integration_guide.md)
- [認証情報管理](02_services/secrets_management.md)
- [バージョン採択方針](02_services/version_policy.md)

### 03_workflows
- [アセット生成ワークフロー](03_workflows/asset_generation_workflow.md)
- [シーン構築ワークフロー](03_workflows/scene_assembly_workflow.md)
- [テストワークフロー](03_workflows/testing_workflow.md)
- [ビルド・リリースワークフロー](03_workflows/build_release_workflow.md)
- [障害対応ワークフロー](03_workflows/incident_response_workflow.md)

### 04_standards
- [コーディング規約](04_standards/coding_standards.md)
- [アセット規約](04_standards/asset_standards.md)
- [シーン規約](04_standards/scene_standards.md)
- [命名規約](04_standards/naming_conventions.md)
- [品質ゲート](04_standards/quality_gates.md)

### 05_claude_code
- [協調作業ガイド](05_claude_code/collaboration_guide.md)
- [指示プロトコル](05_claude_code/instruction_protocol.md)
- [対話プロトコル](05_claude_code/dialogue_protocol.md)
- [タスク管理](05_claude_code/task_management.md)
- [プロンプトテンプレート集](05_claude_code/prompt_templates.md)
- [メモリ運用ポリシー](05_claude_code/memory_policy.md)
- [エスカレーション基準](05_claude_code/escalation_policy.md)
- [プロンプト設計ガイド](05_claude_code/prompt_engineering_guide.md)
- [タスク分解ポリシー](05_claude_code/task_decomposition_policy.md)
- [セッションプロトコル](05_claude_code/session_protocol.md)
- [コンテキスト管理](05_claude_code/context_management.md)
- [サブエージェント運用](05_claude_code/agent_orchestration.md)
- [失敗対応プレイブック](05_claude_code/failure_playbook.md)

### 06_operations
- [CI/CD パイプライン](06_operations/ci_cd_pipeline.md)
- [監視・運用](06_operations/monitoring.md)
- [ローカライズ](06_operations/localization.md)
- [配布・ストア運用](06_operations/distribution.md)

### 07_governance
- [ライセンス管理](07_governance/licensing.md)
- [知的財産方針](07_governance/ip_policy.md)
- [AI 倫理ガイドライン](07_governance/ai_ethics.md)

### 08_process
- [開発フロー定義](08_process/development_flow.md)
- [レビュー手順](08_process/review_procedure.md)
- [ブランチ戦略・コミット規約](08_process/branching_and_commits.md)
- [Definition of Ready / Done](08_process/definition_of_ready_done.md)
- [意思決定ログプロトコル(ADR / RFC)](08_process/decision_log_protocol.md)

---

## 参照・運用ルール

- 本ドキュメントは **唯一の正(Single Source of Truth)** として扱う
- 実装と齟齬が生じた場合、まず本ドキュメントを更新し、続いて実装を修正する
- Claude Code はセッション開始時、最低限 `README.md`、プロジェクトルートの `CLAUDE.md`、関連する各セクションを参照する
- バージョン情報・固有値の変更は `docs/02_services/version_policy.md` の手順に従う
