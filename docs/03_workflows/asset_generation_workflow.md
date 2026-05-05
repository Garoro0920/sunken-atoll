# アセット生成ワークフロー

## 1. 目的

本ワークフローは、3D メッシュ・テクスチャ・HDRI・アニメーション・音響・ボイスといった生成系アセットを **API 駆動で取得し、Godot プロジェクトへ統合可能な形** に整える手順を規定する。

## 2. 起点

以下のいずれかを起点とする:
1. `specs/` 配下の仕様書から Claude Code が必要アセットを抽出
2. オペレータが特定アセットを直接指示
3. 視覚回帰や品質ゲート不通過を起因とする再生成

## 3. 共通フロー

```
[1] 必要アセット定義
      └→ name, kind(mesh|texture|audio|...), purpose, constraints(polycount等)
[2] プロンプト構築
      └→ pipeline/prompts/<id>.json を保存
[3] サービス選定(L1〜L9, 02_services/service_catalog.md)
[4] API 呼出(API 統合ガイドに従う)
      └→ pipeline/api_calls/<date>.jsonl
[5] 受領・チェックサム検証
      └→ assets/raw/<kind>/<id>.<ext>
[6] 加工・最適化(必要に応じて)
      └→ assets/optimized/<kind>/<id>.<ext>
[7] メタデータ記録(ライセンス・帰属・パラメータ)
      └→ pipeline/metadata/<id>.json
[8] Godot 配置
      └→ res://assets/... に配置
[9] ヘッドレス再インポート
      └→ godot --headless --import
[10] 品質ゲート(04_standards/quality_gates.md)
[11] 不合格時はリトライ・パラメータ調整・代替サービス
```

## 4. メッシュ生成手順

### 4.1 入力定義
- 用途(キャラクター / プロップ / 環境)
- ポリゴン上限
- リグの要否(キャラクターは原則必要)
- スタイル(リアル / スタイライズド / ローポリ)

### 4.2 推奨経路
- リグ要: Tripo(Auto-Rig 同時) → 必要に応じて Meshy でテクスチャ強化
- 静的: Meshy 単独 → GLB 直接 Godot 配置
- 高精細: Rodin → Blender 中継でリトポ → 再エクスポート

### 4.3 Godot 取込
- 第一推奨形式: **GLB**(glTF 2.0)
- リグ含む既存資産: FBX(ufbx インポータ)
- インポート設定(`*.import`)で次を確認:
  - VRAM 圧縮(プラットフォーム別)
  - Generate UV2(ライトマップ用)
  - Skeleton 設定の正しさ

### 4.4 検証
- `04_standards/asset_standards.md` 準拠
- バウンディングボックスの異常値検出
- マテリアルがすべて割り当たっていること
- アニメーションが含まれる場合 RESET トラックがあること

### 4.5 サービス個別ガイド

- Tripo: `02_services/tripo.md`
- Meshy: `02_services/meshy.md`

採用決定の根拠と最初に固定すべきパラメータ(モデル名・credit 上限など)は `pipeline/decisions/2026-05-05_island_assets_meshy_tripo_adoption.md` を参照。

### 4.6 島アセット取込(Sprint 2 以降)

漂着島(`scenes/levels/stranding/stranding_demo.tscn` の長期版)で必要となる代表的アセットを、サービス選定の指針付きで列挙する。

| アセット | 推奨サービス | 形式 | Godot インポート要点 |
|---|---|---|---|
| 大型ランドマーク岩・崖 | Tripo Refine | GLB | UV2 自動生成 ON、コリジョン用ローポリ別出力 |
| 小型岩・砂利クラスタ(量産) | Meshy(Image to 3D + Refine) | GLB | UV2 自動生成 ON、LOD は Sprint 後半で対応 |
| 流木・漂着デブリ | Meshy(Text to 3D) | GLB | UV2 自動生成 ON、衝突は trimesh で十分 |
| 植生クラスタ(草・低木) | Meshy(Text to 3D, low-poly 指定) | GLB | アルファカット透過、両面描画(`cull_mode = 0`) |
| 砂・岩地のシームレステクスチャ | Stability AI(タイル化対応設定) | PNG/EXR | sRGB / Linear 設定を Albedo / 他で分離(`asset_standards.md` §4.1) |
| ホワイトボックスのリテクスチャ | Tripo Texturing(主要)/ Meshy Texture(副) | PBR セット | ORMMaterial3D で R=AO / G=Roughness / B=Metallic を採用 |
| プレイヤー/NPC キャラ | Tripo(Image to Model + Auto-Rig) | GLB | Skeleton 命名統一、RESET トラック必須 |

#### 標準フロー(島オブジェクト 1 件あたり)

1. 仕様確定: `specs/features/` の該当節 or 本ワークフロー §3 [1] に従い、`name / kind / purpose / constraints` を `pipeline/prompts/<id>.json` に保存
2. Tripo / Meshy の Draft で **構図・形状の合意** を取る(低コスト枠で複数バリエーション出し)
3. 採用 1 案を Refine に昇格(必要時)。Refine は枠を消費するため事前に PO 承認(`05_claude_code/escalation_policy.md`)
4. 受領 GLB を `assets/raw/<kind>/<id>.glb` に保存、SHA-256 チェックサム確認
5. 必要時 Blender headless でリトポ・LOD・UV2 整え `assets/optimized/<kind>/<id>.glb`
6. `res://assets/...` に配置 → `godot --headless --import` で再インポート
7. メタデータ(prompt / seed / model / cost / license)を `pipeline/metadata/<id>.json` に記録
8. `04_standards/quality_gates.md` のアセット閾値を通過するまでパラメータ調整 or 代替サービス

#### 環境設定チェックリスト(初回起動時)

- [ ] `MESHY_API_KEY` を OS シークレットストア + ローカル `.env` に登録(`02_services/secrets_management.md` §3、`.env.example` を `.env` にコピーして空欄を埋める)
- [ ] `TRIPO_API_KEY` を同様に登録
- [ ] `DRY_RUN=true` のままモック呼出で疎通確認(`02_services/api_integration_guide.md` §7)
- [ ] `pipeline/api_calls/` ディレクトリの存在確認(無ければ作成)
- [ ] `pipeline/metadata/` ディレクトリの存在確認(無ければ作成)
- [ ] Pro プランの月間 credit / 同時ジョブ数を初回呼出時に計測し、`pipeline/decisions/` の利用初回ログに記録
- [ ] 商用利用可否を Pro プランの当時の利用規約で確認、URL を decision log に転記

## 5. テクスチャ生成手順

- 主用途: メッシュ補完、シームレスタイル、UI、デカール
- シームレスが必要な場合は **タイル化対応サービス** を使う
- PBR 完備で受領(Albedo / Normal / Roughness / Metallic / AO)
- ORM パック対応マテリアルを優先採用
- インポートで sRGB / Linear の色空間設定を正しく分ける(Albedo は sRGB、その他は Linear)

## 6. HDRI 生成手順

- 動的生成: Blockade Labs Skybox AI(プロンプト指定)
- 既製: Poly Haven の CC0 を優先
- Godot 側: WorldEnvironment の Sky に Panorama Sky として設定
- 露出値・トーンマッピングは別途調整

## 7. アニメーション生成手順

### 7.1 mocap(動画 → モーション)
- 入力動画は前処理(クロップ・FPS 統一)してから送信
- 出力 FBX または GLB を Godot に配置
- ボーン命名規約に合わせてリネーム(`04_standards/asset_standards.md` 参照)

### 7.2 text → motion
- DeepMotion SayMotion 等を利用
- 用途を明確化(攻撃 / 待機 / 歩行 / 走行 / ダメージ)
- AnimationLibrary に格納し名前空間を分ける

### 7.3 リターゲット
- 標準化したスケルトンを 1 つ決め、すべてのキャラを retarget で寄せる
- ボーン階層が異なる場合は Blender 中継を許容

## 8. リップシンク生成手順

- Audio2Face NIM(クラウド)またはセルフホスト Docker を使用
- 音声 → 顔ブレンドシェイプ系列 → glTF morph として Godot 取込
- AnimationPlayer で音声と同期

## 9. 音響生成手順

### 9.1 BGM
- ジャンル・テンポ・尺・ループ要否を明確に指示
- AIVA 利用時は MIDI 出力も保存し、再編集可能にする
- ループは無音間や境界クロスフェード処理を行う
- ライセンス記録は必須(完全著作権譲渡か RF か)

### 9.2 SFX
- 短尺(秒単位)・ループ要否・カテゴリ(打撃 / UI / 環境)を明確化
- 同種で複数バリエーション生成 → AudioStreamRandomizer に登録

### 9.3 アンビエント
- ループ可能な長尺(数十秒〜分)
- 距離減衰前提で正規化レベルを揃える(後段で Godot 側調整)

### 9.4 ボイス
- TTS は声優役割(主人公・敵・ナレーター等)ごとに固定声を割当
- ローカライズ言語を一覧化して全言語生成
- 必要に応じて Audio2Face と組み合わせリップシンク連携

## 10. 既製アセット取込手順

- Poly Haven / Sketchfab API でメタ情報込みで取得
- ライセンス自動チェック(CC0 / CC-BY / 商用可)
- 帰属表示が必要な素材は `localization/credits.md` に登録
- ファイル形式が GLB 以外なら変換(必要に応じて Blender 中継)

## 11. 加工・最適化

| 加工 | 用途 |
|---|---|
| リトポ | ポリゴン削減・四角化 |
| LOD 生成 | 距離別表示 |
| テクスチャ圧縮 | BC7 / ETC2 / ASTC 切替(プラットフォーム別) |
| アトラス化 | ドローコール削減 |
| Mipmap | テクスチャ縮小階層 |
| UV2 生成 | ライトマップ用 |

これらは可能な限り **API 内のリメッシュ機能** または Blender headless モードで自動化する。

## 12. メタデータ最低記録項目

- `id`、`kind`、`service`、`model`、`prompt`、`seed`、`parameters`
- `license`、`attribution`、`generated_at`
- `input_files`、`output_files`、`checksum`
- `cost_estimate_usd`(可能なら)

詳細フォーマットは `01_architecture/data_flow.md` 参照。

## 13. リトライと代替

- API 失敗時は `02_services/api_integration_guide.md` のリトライ規定に従う
- 品質不合格時は次のいずれか:
  - パラメータ調整(プロンプト、シード、ポリ数)で再生成
  - 代替サービスにフェイルオーバー
  - エスカレーション(`05_claude_code/escalation_policy.md`)

## 14. 完了定義

- アセットが Godot プロジェクトへ正常インポートされる
- メタデータが記録されている
- 品質ゲートを通過している
- ライセンスが商用可と確認されている

## 15. 参照
- API 統合: `02_services/api_integration_guide.md`
- アセット規約: `04_standards/asset_standards.md`
- 品質ゲート: `04_standards/quality_gates.md`
