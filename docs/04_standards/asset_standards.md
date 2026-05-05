# アセット規約

## 1. 目的

3D メッシュ・テクスチャ・マテリアル・アニメーション・音響などのアセットが満たすべき形式・品質基準を定める。

## 2. 共通

- 形式: 第一推奨は **GLB(glTF 2.0)**、リグ既存資産は FBX
- 単位: メートル、Y-up、右手座標
- メタデータを必ず `pipeline/metadata/<id>.json` に記録
- ライセンス情報は **必須**

## 3. メッシュ

### 3.1 ポリゴン目安
プロジェクト用途に応じてプロジェクト開始時に決定するが、目安として:
- メイン操作キャラ: 中ポリ帯
- 背景プロップ: 低〜中ポリ帯
- 環境メッシュ: 低ポリ + 詳細はテクスチャ

### 3.2 トポロジ
- アニメーションが必要な部位は **四角ポリゴン優先**
- N-gon 禁止
- 重複頂点・孤立頂点・反転法線禁止

### 3.3 UV
- 主 UV(チャンネル 0): テクスチャ
- 副 UV(チャンネル 1, UV2): ライトマップ用、Godot 自動生成可
- スケールは UV 空間 [0,1] 内に収める

### 3.4 オリジン・ピボット
- キャラクター: 足元中央が床に接する
- プロップ: 床/設置面の中央
- 武器: グリップ部
- 例外は仕様に明記

### 3.5 LOD
- 必要な距離帯ごとに LOD0/1/2 を用意
- ポリ削減率はサービス側のリメッシュで自動化、最終確認は人間 or Vision

## 4. テクスチャ

### 4.1 PBR チャンネル
- Albedo(Base Color): sRGB
- Normal: Linear、OpenGL 規約(Y+)
- Roughness: Linear、グレースケール
- Metallic: Linear、グレースケール
- AO: Linear、グレースケール
- Emissive: sRGB

### 4.2 ORM パック
- Godot ORMMaterial3D を使う場合 R=AO / G=Roughness / B=Metallic
- glTF metallicRoughnessTexture と互換

### 4.3 解像度
- 主要オブジェクト: 2K(2048×2048)
- 副オブジェクト: 1K
- UI 個別パーツ: 必要最小
- モバイルは半分以下を想定

### 4.4 圧縮
- 配布時は VRAM 圧縮(BC7 / ETC2 / ASTC)
- HDR(EXR/HDR)は LDR 化または BC6H

### 4.5 シームレスタイル
- 環境テクスチャ(壁・地面)はシームレス必須
- 視認可能な繰返しを避けるためバリエーションかブレンドを併用

## 5. マテリアル

- 既定は **StandardMaterial3D**
- パック PBR を使う場合は **ORMMaterial3D**
- 共有マテリアルは `resources/materials/` に外部化(`.tres`)
- インポート時の組込マテリアルは編集しない(再インポートで消える)
- 透明 / 半透明は最小限(描画コスト・ソート問題)

## 6. アニメーション

### 6.1 命名
- AnimationLibrary 内のクリップ名: `snake_case`
- 主要状態: `idle`, `walk`, `run`, `jump`, `attack_<n>`, `hit`, `die`
- 表情/モーフ: `face_<emotion>`

### 6.2 RESET トラック
- インポート時に Rest pose を RESET アニメとして含める
- AnimationTree で常に RESET → 状態遷移の構成を取る

### 6.3 ボーン命名
- 標準: `Hips / Spine / Chest / Neck / Head / ...`(ヒューマノイド)
- すべてのキャラで統一(リターゲット用)
- ボーン数の上限は GPU スキニング限界以内

### 6.4 ループ
- ループ可能なクリップは AnimationPlayer の loop_mode を設定
- 端点が滑らかに繋がること

## 7. 音響

### 7.1 形式
- BGM: Ogg Vorbis(ステレオ)
- SFX: Ogg Vorbis または WAV(短尺)
- ボイス: Ogg Vorbis(モノラル可、必要に応じてステレオ)

### 7.2 サンプルレート / ビット深度
- 通常: 48 kHz / 16 bit
- 高品質: 48 kHz / 24 bit(必要なら)

### 7.3 ノーマライズ
- BGM: -14 LUFS 目安
- SFX: ピーク基準で揃える
- ボイス: -16 LUFS 目安、ノイズリダクション後

### 7.4 ループ
- 完全ループは無音間ゼロ、波形連続
- AudioStreamRandomizer で SFX バリエーション

### 7.5 3D 空間音響
- 3D 効果が必要な音は AudioStreamPlayer3D
- 距離減衰カーブをアセット側でなくシーン側で設定

## 8. HDRI

- 形式: EXR または HDR
- 解像度: 4K 以上(必要に応じて)
- 露出値はインポート後にプロジェクト側で調整
- WorldEnvironment の Sky に Panorama として割当

## 9. メタデータ最低項目

`01_architecture/data_flow.md` の節「メタデータ仕様」を参照。

## 10. 命名

`04_standards/naming_conventions.md` を参照。

## 11. 検証

- 自動: `tools/asset_lint.py`(チャンネル数、解像度、容量、命名)
- Godot 側: インポート警告 0 を CI で強制
- 視覚: 最低 1 シーンで配置スクショを Vision で確認

## 12. アンチパターン

- 過剰解像度のテクスチャ
- ボーンが Mixamo 命名でないキャラの混在(リターゲット不能)
- マテリアルをスクリプトで毎フレーム生成
- WAV 巨大ファイルを BGM に使う
- ライセンス未記録のアセットコミット

## 13. 参照
- アセット生成: `03_workflows/asset_generation_workflow.md`
- 命名: `04_standards/naming_conventions.md`
- ライセンス: `07_governance/licensing.md`
