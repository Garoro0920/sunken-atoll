# Spec: 水面・水中レンダリング

| 項目 | 内容 |
|---|---|
| 状態 | Draft |
| 親 GDD | `specs/game_design_document.md` §1.5 / §7.2 / §7.3 |
| 起票日 | 2026-05-05 |
| 関連規約 | `docs/04_standards/asset_standards.md` §5(マテリアル)、`docs/04_standards/coding_standards.md` §5(シェーダ) |

## 1. 目的

本作の世界観の中核である **「水没した世界の湿潤・退廃感」** を支える、水面シェーダと水中ボリューメトリック描画系を構築する。性能・ゲームプレイ要件・アート要件をすべて満たす再利用可能なマテリアル群を提供する。

## 2. ユーザストーリー

- プレイヤーとして、水面・水中・浅瀬・深海で見た目が明確に変化し、現在地の危険度を視覚的に判断できる。
- アーティストとして、各環境帯ごとに色味・濁度・反射を調整できる。
- 開発者として、シェーダ性能の劣化を CI で検出できる。

## 3. 要件

### 3.1 水面シェーダ

| 機能 | MVP | ストレッチ |
|---|---|---|
| 基本反射 | リアルタイム反射(SSR or プローブ) | 二重反射 / 動的キューブマップ |
| 屈折 | 画面空間屈折(深さ依存) | 物理ベース屈折 |
| 波 | Gerstner 波 × 3〜4 重ね合わせ + ノイズ | FFT 波 |
| 泡(白波) | 衝突・浅瀬・速度ベース | 動的密度 |
| 海岸線 | 浅瀬で透過率上昇 | 動的湿潤マスク |
| 嵐対応 | 波振幅 / 周期を風速パラメータ制御 | 動的雨痕 |

### 3.2 水中描画

- ボリューメトリック散乱(深度ベースのフォグ + ライトシャフト)
- 水中限定ポストプロセス(色調・歪み・低周波音響フィルタ連動)
- ヘッドライト円錐の局所散乱
- カメラが水面を跨ぐときの境界処理(部分水中表示は MVP では簡易、ストレッチで物理的表現)

### 3.3 ゲームプレイ連動

- **視界距離**: 環境帯と濁度パラメータで動的変化
- **酸素 UI 連動**: 酸素低下時にビネット強化(survival_balance §3.3 と統合)
- **派閥/危険連動**: 汚染海域は色味・粒子で判別可能

### 3.4 非機能要件

| プラットフォーム | 水面 GPU 予算 | 水中 GPU 予算 |
|---|---|---|
| デスクトップ高(1440p, 60fps) | 2.0 ms | 1.5 ms |
| デスクトップ標準(1080p, 60fps) | 1.5 ms | 1.0 ms |
| Steam Deck(720p, 40fps) | 2.0 ms | 1.5 ms |

- マルチプレイ非依存(クライアント側完結、同期不要)
- 共有マテリアルは `resources/materials/water/` に外部化
- シェーダは `resources/shaders/water/` に配置(`.gdshader` / `.gdshaderinc`)

### 3.5 テスト観点

- 視覚回帰: 浅瀬 / 半水没都市 / 沿岸遺跡 / 深海帯の代表シーンで baseline 4 枚以上
- パフォーマンス: 上記予算をベンチマークシーンで計測、CI で劣化検出
- 機能: 嵐パラメータ連続変化でアーティファクトなし
- 視覚: Vision で「ピンク・真っ黒・縞・Z-fighting なし」を判定(`docs/03_workflows/testing_workflow.md` §8)

## 4. 非要件 / スコープ外

- 水中の流体物理シミュレーション(粒子の流れ等)は MVP 外
- 海中生物のシルエット透過(将来エンカウンター演出)は MVP 外
- リアルタイム雨痕(`Wet Detail Map`)はストレッチ

## 5. 受入基準(DoD)

- [ ] 水面マテリアル(`water_surface.tres`)と水中ポストプロセス(`underwater.tres`)が完成
- [ ] 4 環境帯のパラメータプリセットが `.tres` で外部化
- [ ] ベンチマークで GPU 予算内
- [ ] 視覚回帰ベースライン登録、Vision 判定 OK
- [ ] アーティスト向け簡易ドキュメント(`docs/04_standards/asset_standards.md` 補足として配置)

## 6. 想定実装

- 配置: `resources/shaders/water/`、`resources/materials/water/`、`scenes/prototypes/water_test.tscn`
- 触ってよいパス: 上記 + `tests/visual/scenarios/water/`、`tests/perf/water_benchmark.gd`
- 触らないパス: `src/gameplay/`、`src/networking/`(描画専用 spec のため)

## 7. リスクと未決事項

| リスク | 対策 |
|---|---|
| Steam Deck で予算超過 | 簡易モデルへの自動切替を Renderer 設定で用意 |
| SSR の品質ばらつき | プローブ方式 + 反射範囲制限で fallback |
| Forward+ vs Mobile レンダラ選択 | プロト時に決定し ADR 化 |
| Jolt 物理との浮体相互作用での波高同期 | 物理は別 tick、見た目は補間で吸収 |

## 8. 参照

- GDD: §1.5、§7.2、§7.3
- `docs/04_standards/asset_standards.md` §5
- `docs/04_standards/coding_standards.md` §5
- `docs/03_workflows/testing_workflow.md` §7、§10
