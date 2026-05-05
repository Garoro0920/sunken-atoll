# Meshy AI

`02_services/service_catalog.md` §3 L1(3D メッシュ生成・代替候補)および L2(テクスチャ・メッシュ貼付)で採用するサービスの個別ページ。共通方針は `02_services/api_integration_guide.md` を参照すること。

## 1. 役割

| レイヤ | 用途 | 本作での主な使い所 |
|---|---|---|
| L1 メッシュ生成(代替) | 静的プロップを image / text から短時間で生成 | 岩、流木、ドラム缶、漂着物、植生クラスタ |
| L2 テクスチャ生成(代替) | 既存メッシュへの PBR テクスチャ自動貼付 | ホワイトボックスメッシュへの後付けマテリアリゼーション |

リグ要のキャラクターは Tripo(主)を優先。Meshy は **静的・量産系の代替**。

## 2. リファレンス

| 項目 | 値 |
|---|---|
| 公式サイト | https://www.meshy.ai/ |
| API ドキュメント | https://docs.meshy.ai/ |
| 採用バージョン / モデル名 | `02_services/version_policy.md` §9.3 を参照(初回呼出時に固定) |
| 認証方式 | API キー(Bearer)。`MESHY_API_KEY` 環境変数(`02_services/secrets_management.md` §4) |
| 通信 | HTTPS REST、ジョブ非同期(submit → poll / webhook) |
| プラン | Pro(本作)— 同時実行・月間生成数の上限はプラン依存。`02_services/api_integration_guide.md` §9 のレート/コスト制御に従う |

## 3. 主要エンドポイント

具体パスは公式ドキュメントを正とするが、本パイプラインで利用する系統:

| 系統 | 入力 | 出力 |
|---|---|---|
| Text to 3D | プロンプト + スタイル + ポリ上限 | GLB / FBX / OBJ + テクスチャ |
| Image to 3D | 単視点 / 多視点画像 | 同上 |
| Texture to Mesh | 既存メッシュ + プロンプト | PBR セット(Albedo/Normal/Roughness/Metallic) |
| Refine / Remesh | ジョブ ID 指定 | 高解像度出力 |

非同期ジョブの polling / timeout / リトライは `api_integration_guide.md` §3.2 / §4 に従う。

## 4. 出力形式と取込

- 第一推奨は **GLB**(`04_standards/asset_standards.md` §2)
- テクスチャは PBR セット(Albedo は sRGB、Normal/Roughness/Metallic は Linear、`asset_standards.md` §4.1)
- Godot へのインポート設定は `03_workflows/asset_generation_workflow.md` §4.3 の `*.import` チェックリストを参照
- ライセンスメタは `pipeline/metadata/<id>.json` に商用可否(Pro プランの利用規約に基づく)を必ず記録

## 5. 本作での使い分け

| 島アセット | 主 | 代替 |
|---|---|---|
| 岩・崖プロップ | Meshy(Image to 3D、量産)| Tripo Refine |
| 流木 / 漂着デブリ | Meshy(Text to 3D、シンボリック生成)| 既製 + Sketchfab |
| 植生クラスタ(草・低木) | Meshy(Text to 3D、ローポリ)| Tripo |
| ホワイトボックスのマテリアリゼーション | Meshy Texture | Stability(タイル化テクスチャ) |

詳細フローは `03_workflows/asset_generation_workflow.md` §4.6「島アセット取込」を参照。

## 6. レート制限・コスト

- 同時ジョブ数・日次上限は Pro プランの実値を **初回呼出時に計測** し、`pipeline/decisions/` の使用初回ログに記録する
- 高単価ジョブ(Refine、4K テクスチャ)は人間承認(`05_claude_code/escalation_policy.md`)を経由する
- API 呼出は `pipeline/api_calls/<YYYY-MM-DD>.jsonl` に逐次記録

## 7. 商用ライセンス

- Meshy Pro プランの利用規約を確認の上、生成物を本作で **再配布(Steam 配布物)できる** ことを `pipeline/metadata/<id>.json` の `license` 欄に明記する
- ライセンス文書 URL: 初回呼出時に当時の規約 URL を decision log に記録(規約は更新されうるため)

## 8. フェイルオーバー

| 障害 | 一次対応 | 代替 |
|---|---|---|
| 5xx / タイムアウト | バックオフリトライ(`api_integration_guide.md` §4) | Tripo |
| 429 レート上限 | キューイング | Tripo |
| 出力品質不合格 | パラメータ調整 → 再生成(プロンプト・シード変更) | Tripo Refine、または既製アセット(Poly Haven / Sketchfab) |
| サービス停止 | フェイルオーバー切替を `pipeline/decisions/` に記録 | Tripo を主に格上げ |

## 9. 障害連絡先・SLA

- 公式サポート窓口は公式サイトの Help / Contact を参照
- 本作プランでの SLA は契約条項を `pipeline/decisions/2026-05-05_island_assets_meshy_tripo_adoption.md` の関連節に転記(必要時)

## 10. 参照

- 共通 API 統合方針: `02_services/api_integration_guide.md`
- シークレット管理: `02_services/secrets_management.md`
- バージョン採択: `02_services/version_policy.md`
- アセット生成ワークフロー: `03_workflows/asset_generation_workflow.md`
- アセット規約: `04_standards/asset_standards.md`
- 採用決定ログ: `pipeline/decisions/2026-05-05_island_assets_meshy_tripo_adoption.md`
