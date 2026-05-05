# 2026-05-05 初期化完了:バージョン採択ロック・タイトル確定・ライセンス選択

## 文脈

`CLAUDE.md` §9「補助情報」が定める初期化要件 3 件のうち、これまでに #3「`project_charter.md` のスコープと成功基準調整」が消化済み(`2026-05-05_gdd_initial.md`)で、残り 2 件(#1 バージョンマトリクス、#2 品質ゲート閾値マトリクス)が未消化だった。
本決定で残作業を一括消化し、加えて GDD §9 Q-01(正式タイトル)、`07_governance/licensing.md` §2(ライセンス選択)も併せて確定する。

PO(オペレータ)より、`2026-05-05_version_proposal.md` 提案に対する承認、ならびにタイトル確定・ライセンス選択の実行指示を受領。

## 決定内容

### D-01: バージョン採択ロック

`pipeline/decisions/2026-05-05_version_proposal.md` の **A 群を承認・ロック**。同時に B 群の提案値も暫定ロックとして転記。C 群は使用工程到達時に個別決定ログで採択、D 群は不採用を明示。

転記先: `docs/02_services/version_policy.md` §9(本決定で更新済)

主要採択値:

| 領域 | 採択 |
|---|---|
| Engine | Godot 4.6.2 |
| Physics | Jolt(Godot 4.6 同梱) |
| Steam 統合 | GodotSteam GDExtension 4.18.1(Steamworks SDK 1.64) |
| LLM | Claude Opus 4.7(`claude-opus-4-7`) |
| Test | GdUnit4 v5.0.4(v6.0.x は Godot 4.5 専用で互換切れのため採用禁止) |
| Crash 監視 | Sentry Godot SDK 1.6.0 |
| Lang | Python 3.12.x、Node.js 20 LTS、.NET 未採用 |
| 配布 | butler(rolling)、steamcmd(rolling) |

調査出典は `2026-05-05_version_proposal.md` 末尾を参照。

### D-02: 正式タイトル確定

**「Sunken Atoll」** を正式タイトルとして確定。

| 項目 | 内容 |
|---|---|
| 旧仮称 | Project Sunken Atoll(仮) |
| 新正式名 | **Sunken Atoll** |
| 確定根拠 | 既に各文書で 2 セッション運用されており命名コストの再投資を回避、IP リスク回避(SUNKENLAND と語形・音韻ともに明確に異なる)、「沈んだ環礁」という世界観中核とも整合 |

#### 反映箇所(本決定で更新済)
- `specs/game_design_document.md`(冒頭メタ + §9 Q-01)
- `docs/00_overview/project_charter.md`(冒頭表)
- `project.godot`(`config/name`、`config/description`)
- `README.md`(タイトル + ライセンス節)

#### 履歴保持(更新せず原文保持)
- `pipeline/decisions/2026-05-05_gdd_initial.md`
- `pipeline/decisions/2026-05-05_version_proposal.md`
- `pipeline/escalations/2026-05-05_ip_similarity_check.md`
  → 過去の意思決定ログは **不変原則**(`08_process/decision_log_protocol.md` §4)に従い、当時の表記(Project Sunken Atoll(仮))のまま保持する。本決定がそれらの後継であることを本ファイルで明示することで履歴の追跡性を確保する。

### D-03: ライセンス選択

**Proprietary / All Rights Reserved** を採用。

| 項目 | 内容 |
|---|---|
| 採用 | All Rights Reserved(プロプライエタリ) |
| 配置 | リポジトリルートの `LICENSE`(本決定で配置済) |
| 著作権者 | **`[Copyright Holder TBD]` プレースホルダ**(法的実体確定時に差替) |
| 第三者依存 | 各原ライセンスに従う(`localization/credits.md`、`pipeline/metadata/<id>.json`、`docs/07_governance/licensing.md`) |

#### 採用理由
- 本作は **商用 Steam リリース** を前提(GDD §7.4、`docs/06_operations/distribution.md`)
- `docs/07_governance/licensing.md` §2 の選択肢(MIT / Apache-2.0 / GPL 系 / プロプライエタリ)のうち、商用配布の自由度を最大化する選択
- OSS 依存 + 生成系アセットの権利継承を妨げない構成(LICENSE で第三者ライセンスは原ライセンスに従う旨を明記)

#### 不採用とした選択肢
- **MIT / Apache-2.0**: 本作の中核アセット(将来生成される独自アート・音響・コード)を再配布可能にしてしまい、商用価値を損なう
- **GPL 系**: 採用 OSS 依存(GodotSteam、GdUnit4 等)のライセンスとの両立が複雑化、商用配布の制約大

## 結果(期待される効果)

- `CLAUDE.md` §9 初期化要件 3 件すべて消化 → **本格作業の着手が可能**
- バージョン採択ロックにより再現性が保証される
- 正式タイトル確定により外部参照(設計議論・将来のストア提出書類・ドメイン取得など)で表記ブレが解消
- ライセンスを早期に明示しておくことで、貢献者・第三者との関係性が明確

## 引き換えのリスク

| リスク | 対応 |
|---|---|
| Godot 4.6.x で想定通りに動かない事象が発生 | プロト工程(`specs/epics/prototype_phase.md`)で発見し、必要なら 4.6.1 / 4.6 へのダウングレードを検討、改訂は本ログ後継として記録 |
| GdUnit4 v5.0.4 が将来の Godot バージョンに追随しない | 4.6 → 4.7 移行時に GUT 等代替評価 |
| LLM コスト想定超過 | `specs/features/ai_npc_dialog.md` §3.6 のセッション/月次予算ガード |
| 「Sunken Atoll」の商標調査未実施 | F-06(`pipeline/escalations/2026-05-05_ip_similarity_check.md`)のチェック観点に従い、コンセプトアート初稿前に PO + 法務助言で確認 |
| 著作権者プレースホルダのまま外部配布 | 本ログ §フォロー F-04 で監視 |

## フォロー

| # | 作業 | 担当 | トリガ |
|---|---|---|---|
| F-01 | プロト工程開始(`specs/epics/prototype_phase.md`)— 水面 / 浮体 / 4 人接続を並列検証 | Claude Code | 本承認直後 |
| F-02 | プロト DoD 達成度を見て、必要に応じて `quality_gates.md` §9 の閾値を実測値で更新 | Claude Code | 各プロト完了時 |
| F-03 | C 群サービス(アート / 音響 / バックエンド等)は使用工程到達時に **個別決定ログ** を起票し、`version_policy.md` §9.3 を更新 | Claude Code | 各工程開始時 |
| F-04 | 外部配布(プライベートアルファ含む)前に **`LICENSE` 内 `[Copyright Holder TBD]` を法的実体名に差替** | PO | 配布前必須 |
| F-05 | 「Sunken Atoll」の **商標調査**(US / EU / JP / 中国 / 韓国 主要市場) | PO + 必要に応じ法務 | コンセプトアート初稿前 |
| F-06 | `localization/credits.md` の Production 欄に正式チーム名を記入 | PO | 法的実体確定時 |
| F-07 | Godot 4.7 リリース時の互換性確認(nightly ジョブ設置) | Claude Code | Godot 4.7 stable リリース後 |

## 関連

- 親決定: `pipeline/decisions/2026-05-05_gdd_initial.md`、`pipeline/decisions/2026-05-05_version_proposal.md`
- 関連エスカレーション: `pipeline/escalations/2026-05-05_ip_similarity_check.md`
- 規約: `CLAUDE.md` §9、`docs/02_services/version_policy.md`、`docs/04_standards/quality_gates.md`、`docs/07_governance/licensing.md`、`docs/07_governance/ip_policy.md`、`docs/08_process/decision_log_protocol.md`
- 中核仕様: `specs/game_design_document.md`、`specs/epics/prototype_phase.md`
- 配置物: リポジトリルート `LICENSE`、`project.godot`、`README.md`、`docs/00_overview/project_charter.md`

## 状態

**Accepted**(承認・実施済)。本決定は不変。後続の改訂は新規 ADR / 決定ログとして起票し、本決定を `Superseded by` メタで参照する。
