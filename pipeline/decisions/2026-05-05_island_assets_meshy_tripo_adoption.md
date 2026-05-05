# 2026-05-05 島アセット生成における Meshy / Tripo Pro 採用

## 文脈

`pipeline/decisions/2026-05-05_initialization_complete.md` フォロー F-03 が「C 群サービス(アート / 音響 / バックエンド等)は使用工程到達時に **個別決定ログ** を起票し、`version_policy.md` §9.3 を更新」と規定している。

Sprint 1 の `stranding_demo.tscn` までは島・水面・プレイヤーをすべてプリミティブメッシュ + 単純マテリアルで構成し、ゲームループの妥当性検証を優先した。Sprint 2 以降では、漂着島の世界観を支える 2D / 3D アセット(岩・流木・植生・ランドマーク・砂/岩テクスチャ)が必要になる。

PO が **Meshy AI Pro** および **Tripo AI Pro** を契約済みであり、これらのサービスを島アセット生成の中核に据える方針が示された。`02_services/service_catalog.md` ではすでに Tripo を L1 メッシュ生成の主、Meshy を代替候補として位置付けている(`02_services/version_policy.md` §9.3 では C 群「未確定(実装時)」)。

本決定で C 群の該当 2 行を「サービス採用確定」に昇格し、サービス個別ページ・島アセットワークフロー・環境変数テンプレートの整備を一括完了させる。

## 選択肢

- **A: Tripo を主、Meshy を代替に位置付け、両者を併用**
  - 利点: `service_catalog.md` の既存方針と一致。リグ要(キャラ)は Tripo Auto-Rig、量産プロップ(岩・流木)は Meshy で **コスト枠を分散** できる。両者とも Pro プラン契約済で並走に追加投資不要
  - 欠点: 2 サービスの API クライアント・モック・メタデータ運用を二重に整える必要がある

- **B: Tripo Pro 単独で全アセット生成**
  - 利点: クライアント実装が 1 つで済む。生成スタイルを統一しやすい
  - 欠点: Refine 枠が量産プロップで消耗し、主要キャラに割り当てる credit が不足するリスク。Tripo がダウンしたとき即フェイルオーバー先がない

- **C: Meshy Pro 単独で全アセット生成**
  - 利点: クライアント実装が 1 つで済む
  - 欠点: Auto-Rig が弱く、リグ要キャラの品質が落ちる。`service_catalog.md` L1 主が Tripo であり、既存方針との不整合

- **D: 既製アセット中心(Poly Haven / Sketchfab CC0)+ 必要時のみ生成**
  - 利点: コストゼロ。商用利用可ライセンスのアセットが豊富
  - 欠点: 「Sunken Atoll」固有の世界観(沈んだ環礁・漂着の物語性)を構成するために、汎用既製では合致しないものが多数発生する。生成系は早晩必要

## 決定

**A を採用**。

| 役割 | サービス | 根拠 |
|---|---|---|
| L1 主(リグ要キャラ・主要ランドマーク) | Tripo | Auto-Rig 同梱、Refine の品質 |
| L1 代替(量産プロップ) | Meshy | 短時間生成、Image to 3D が直感的 |
| L2 主(主要メッシュのリテクスチャ) | Tripo Texturing | メッシュとの整合性が高い |
| L2 代替(タイル / 既存メッシュ) | Meshy Texture / Stability(別途) | フェイルオーバー枠 |

## 結果(期待される効果)

- `version_policy.md` §9.3 の Tripo / Meshy 行が「サービス採用確定」に昇格、Sprint 2 着手の障害が 1 件解消
- サービス個別ページ(`02_services/tripo.md`、`02_services/meshy.md`)が出揃い、`service_catalog.md` §4「各サービス採用にあたっての必須記録」の要件を充足
- `03_workflows/asset_generation_workflow.md` §4.6 に「島アセット取込」フローが追加され、各アセット種別と推奨サービスの対応が明文化
- `.env.example` に `TRIPO_API_KEY` / `MESHY_API_KEY` がすでに含まれており、PO がローカル `.env` を埋めれば即座に DRY_RUN 疎通テストが可能

## 引き換えのリスク

| リスク | 対応 |
|---|---|
| Pro プラン契約条項(商用配布可否)が将来変更される | F-01 で初回呼出時に当時の利用規約 URL を本ログに追記、改訂は本ログ後継として記録 |
| Pro プランの月間 credit 想定超過 | F-02 で初回計測値を `pipeline/decisions/` に記録、超過予測時は `api_integration_guide.md` §9 のキューイング |
| 生成スタイルが統一されない | F-03 で「島アセットスタイルガイド」を `specs/features/` 配下に新設し、プロンプトテンプレートに集約 |
| Auto-Rig の精度がキャラ要件を満たさない | プロト工程で humanoid 1 体を実際に Auto-Rig し、Blender 中継リトポの要否を判定 |
| 採用モデル(Tripo v?? / Meshy v??)未固定 | F-04 で初回呼出時に固定し `version_policy.md` §9.3 を再更新 |

## フォロー

| # | 作業 | 担当 | トリガ |
|---|---|---|---|
| F-01 | Pro プラン利用規約 URL を `02_services/tripo.md` §7 / `02_services/meshy.md` §7 に転記 | PO + Claude Code | Sprint 2 着手前 |
| F-02 | 初回呼出時に Pro プランの月間 credit / 同時ジョブ数を計測し本ログに追記 | Claude Code | 初回 API 呼出時 |
| F-03 | 島アセットスタイルガイド(色調・トポロジ・スケール)を `specs/features/island_asset_style.md` として新設 | Claude Code | Sprint 2 計画時 |
| F-04 | 採用モデル名(Tripo の Draft/Refine 段階・version、Meshy の version)を初回呼出時に固定し `version_policy.md` §9.3 を更新 | Claude Code | 初回 API 呼出時 |
| F-05 | `pipeline/api_calls/` / `pipeline/metadata/` ディレクトリ未作成なら作成 | Claude Code | 初回 API 呼出時 |
| F-06 | 生成系アセットの商用ライセンス情報を `pipeline/metadata/<id>.json` に記録するツール `tools/asset_metadata.py` の雛形を整備 | Claude Code | 初回呼出時 or Sprint 2 |

## 関連

- 親決定: `pipeline/decisions/2026-05-05_initialization_complete.md`(F-03)
- サービスカタログ: `docs/02_services/service_catalog.md` §3 L1 / L2 / L4
- 個別ページ: `docs/02_services/tripo.md`、`docs/02_services/meshy.md`
- バージョン採択: `docs/02_services/version_policy.md` §9.3
- ワークフロー: `docs/03_workflows/asset_generation_workflow.md` §4.5 / §4.6
- シークレット: `docs/02_services/secrets_management.md`、`.env.example`
- 索引更新: `docs/00_overview/document_index.md`(SV-05、SV-06 追加)

## 状態

**Accepted**(PO 承認・実施済)。本決定は不変。後続の改訂(モデル固定・規約 URL 転記など)は本ログのフォロー欄で参照、または新規決定ログを起票し本決定を `Superseded by` メタで参照する。
