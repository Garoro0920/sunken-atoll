# Tripo AI

`02_services/service_catalog.md` §3 L1(3D メッシュ生成・主)、L2(テクスチャ・メッシュ貼付・主)、L4(Auto-Rig)で採用するサービスの個別ページ。共通方針は `02_services/api_integration_guide.md` を参照すること。

## 1. 役割

| レイヤ | 用途 | 本作での主な使い所 |
|---|---|---|
| L1 メッシュ生成(主) | テキスト / 画像 → 3D + Auto-Rig 同時 | キャラクター、リグ要のクリーチャー |
| L2 テクスチャ生成(主) | Tripo Texturing による高品質 PBR 貼付 | 主要キャラ・主要プロップの仕上げ |
| L4 Auto-Rig | 生成メッシュへの自動リギング | 動かす対象すべて |

静的・量産系プロップは Meshy(代替)を優先することで、Tripo の Refine 枠(コスト・時間)を主要キャラに集中させる。

## 2. リファレンス

| 項目 | 値 |
|---|---|
| 公式サイト | https://www.tripo3d.ai/ |
| API ドキュメント | https://platform.tripo3d.ai/docs |
| 採用バージョン / モデル名 | `02_services/version_policy.md` §9.3 を参照(初回呼出時に固定) |
| 認証方式 | API キー(Bearer)。`TRIPO_API_KEY` 環境変数(`02_services/secrets_management.md` §4) |
| 通信 | HTTPS REST、ジョブ非同期(submit → poll / webhook) |
| プラン | Pro(本作)— 同時実行・月間生成数の上限はプラン依存。`02_services/api_integration_guide.md` §9 のレート/コスト制御に従う |

## 3. 主要エンドポイント

具体パスは公式ドキュメントを正とするが、本パイプラインで利用する系統:

| 系統 | 入力 | 出力 |
|---|---|---|
| Text to Model | プロンプト + スタイル + face_limit | Draft メッシュ(GLB) |
| Image to Model | 単視点 / 多視点画像 + 背景除去オプション | 同上 |
| Refine | Draft ジョブ ID | 高品質メッシュ + テクスチャ |
| Auto-Rig | メッシュジョブ ID + 種別(humanoid 等) | リグ済 GLB / FBX |
| Texturing | 既存メッシュ + プロンプト | PBR テクスチャセット |
| Convert | 別フォーマットへ変換(GLB ⇄ FBX ⇄ OBJ 等) | 指定フォーマット |

非同期ジョブの polling / timeout / リトライは `api_integration_guide.md` §3.2 / §4 に従う。

## 4. 出力形式と取込

- 第一推奨は **GLB**(`04_standards/asset_standards.md` §2)
- リグ含むメッシュは GLB(glTF Skin)を優先、必要に応じて FBX(ufbx インポータ)
- テクスチャは PBR セット(Albedo は sRGB、Normal/Roughness/Metallic は Linear、`asset_standards.md` §4.1)
- Skeleton 命名・ボーン階層は `04_standards/asset_standards.md` §6.3 のヒューマノイド標準に揃え、リターゲット可能性を維持
- Godot へのインポート設定は `03_workflows/asset_generation_workflow.md` §4.3 の `*.import` チェックリストを参照

## 5. 本作での使い分け

| アセット種別 | 主 | 代替 |
|---|---|---|
| プレイヤーキャラ・NPC | Tripo(Image to Model + Auto-Rig) | — |
| クリーチャー(リグ要) | Tripo | — |
| 島の地形プロップ(岩・崖・大型構造物) | Tripo Refine(主要なランドマーク) | Meshy(量産プロップ) |
| 島の小物(漂着物・流木) | Meshy | Tripo |
| 主要プロップのリテクスチャ | Tripo Texturing | Stability(平面タイル) |

詳細フローは `03_workflows/asset_generation_workflow.md` §4.6「島アセット取込」を参照。

## 6. レート制限・コスト

- Pro プラン枠の同時ジョブ数・月間 credit を **初回呼出時に計測** し、`pipeline/decisions/` の使用初回ログに記録
- Refine は Draft の数倍コスト。Refine を実行する前に Draft で **構図・形状の合意** を取ってから昇格すること
- 高単価ジョブ(Refine、Auto-Rig 大型、4K Texturing)は人間承認(`05_claude_code/escalation_policy.md`)を経由する
- API 呼出は `pipeline/api_calls/<YYYY-MM-DD>.jsonl` に逐次記録

## 7. 商用ライセンス

- Tripo Pro プランの利用規約を確認の上、生成物を本作で **再配布(Steam 配布物)できる** ことを `pipeline/metadata/<id>.json` の `license` 欄に明記する
- ライセンス文書 URL: 初回呼出時に当時の規約 URL を decision log に記録(規約は更新されうるため)

## 8. フェイルオーバー

| 障害 | 一次対応 | 代替 |
|---|---|---|
| 5xx / タイムアウト | バックオフリトライ(`api_integration_guide.md` §4) | Meshy |
| 429 レート上限 | キューイング | Meshy |
| 出力品質不合格 | Draft → Refine、シード/プロンプト調整 | Meshy / Rodin |
| Auto-Rig 失敗 | 手動リギング(Blender)or 別 humanoid プリセット | — |
| サービス停止 | フェイルオーバー切替を `pipeline/decisions/` に記録 | Meshy を主に格上げ |

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
