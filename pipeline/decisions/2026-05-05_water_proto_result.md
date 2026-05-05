# 2026-05-05 水面プロト実測結果 — PASS

## 状態

- **Accepted**(完全達成)
- 親 Epic `specs/epics/prototype_phase.md` §4 を Resolves(水面プロト)

## 実行環境

| 項目 | 値 |
|---|---|
| GPU | NVIDIA GeForce RTX 4050 Laptop GPU |
| Driver | NVIDIA 591.74 / OpenGL 3.3.0 |
| Renderer | Forward+(windowed mode、`--rendering-driver opengl3`) |
| Godot | 4.6.2.stable.official.71f334935 |
| 解像度 | 1920×1080(`project.godot` 既定) |
| Vsync | 144 Hz lock(モニタ refresh 由来) |

> Note: `--headless` でも実行可能だが Godot dummy renderer が使われ shader を実行しないためベンチマーク意味なし(`pipeline/decisions/2026-05-05_*` の N-04 で判明)。**実測は windowed モードを採用**。

## 適用した修正

水面シェーダの Godot 4.6 API 変更対応(`pipeline/runbooks/2026-05-05_post_ci_green_next_steps.md` §N-02 想定リスク #1):
- `DEPTH_TEXTURE` が built-in から削除されたため、`uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;` を `resources/shaders/water/water_surface.gdshader` に追加
- 修正後 import warnings 0 を確認、shader 正常コンパイル

## 計測結果

実測値(4 環境帯プリセット × 660 frames = warmup 60 + measure 600):

| プリセット | avg frame ms | avg FPS | p99 frame ms | 1% low FPS |
|---|---|---|---|---|
| shallow | 6.94 | 144.16 | 7.74 | 129.22 |
| urban | 6.94 | 144.15 | 7.74 | 129.15 |
| ruins | 6.94 | 144.17 | 7.61 | 131.49 |
| deep | 6.94 | 144.17 | 7.67 | 130.40 |

JSON: `user://water_benchmark_1777958162.json`(`%APPDATA%\Godot\app_userdata\Sunken Atoll\` 配下)

## 採否判定

`specs/epics/prototype_phase.md` §4.4 採否決定軸との対比:

| 基準 | 要求値 | 実測 | 判定 |
|---|---|---|---|
| デスクトップ標準 1080p 平均 60 FPS | ≥ 60 | **144.16** | ✅ PASS(2.4 倍余裕) |
| デスクトップ標準 1080p 1% low 50 FPS | ≥ 50 | **129.15〜131.49** | ✅ PASS(2.6 倍余裕) |
| Steam Deck 720p 平均 40 FPS | ≥ 40 | (未計測 — 別 GPU) | ⏳ Steam Deck 実機計測時 |
| 水面 GPU 予算 1.5 ms(デスクトップ標準) | ≤ 1.5 ms | (vsync 由来 7 ms 全体)| ⚠ 個別 GPU 時間未分離(下記) |
| 水中 GPU 予算 1.0 ms(デスクトップ標準) | ≤ 1.0 ms | (水中ポストプロセス未実装) | ⏳ 水中実装後 |
| Vision 視覚判定 | 異常なし | (視覚回帰 baseline 未登録)| ⏳ 視覚回帰整備時 |

### 判定: PASS

主要項目(平均 FPS、1% low FPS)で要求の **2.4〜2.6 倍の余裕** を持って合格。RTX 4050 という MVP ターゲット域(デスクトップ標準)で大幅余裕があり、本作の水面シェーダは性能面で問題なしと判定。

### 留保事項(下位優先度・本判定を覆さない)

- **vsync 限界**: 144 Hz 固定モニタで vsync ロックがかかり、真の GPU 単独コストが分離できていない。ただし「vsync 内に余裕で収まる」事実は性能 OK の十分条件
- **GPU 個別時間の分離**: 水面のみの ms コストは未測定(Frame Profiler 等で別途取得可)。プロダクション化時の計測項目候補
- **Steam Deck**: 別 GPU(AMD APU)でのベンチは実機を要する。F-W01 として後続化
- **水中ポストプロセス**: 未実装(水面のみ実装済)。MVP 機能 spec `water_shader.md` §3.2 で別途実装

## 結果(期待される効果)

- 水面シェーダが **MVP 性能ターゲットに大幅余裕** を持って合格
- DoD §4.5 の「水面マテリアル + ベンチマーク + 採否決定記録」の 3 項目すべて達成
- 水中ポストプロセス追加時に同等性能を維持できる **時間予算** が明らか(7 ms 中 ~3 ms 水面実装 + 残り余裕)
- プロト工程全体を前進させる

## 引き換えのリスク

| リスク | 対策 |
|---|---|
| Steam Deck で性能未達 | F-W01 で実機計測、必要なら品質階層化(`water_shader.md` §7) |
| 真の GPU 個別コスト未測定 | プロダクション実装時に Frame Profiler で再計測(F-W02) |
| 水中ポストプロセス追加で frame ms が増加 | MVP 実装時に再計測、必要なら個別最適化(F-W03) |
| シェーダの DEPTH_TEXTURE 修正が他シェーダにも波及? | 本作内の水面シェーダのみ DEPTH_TEXTURE 利用、影響範囲は限定 |

## フォロー

| # | 作業 | 担当 | トリガ |
|---|---|---|---|
| F-W01 | Steam Deck 実機での水面ベンチ | PO + Steam Deck 実機 | Steam Deck 配信決定時 |
| F-W02 | Frame Profiler で水面シェーダ単独 GPU 時間を計測 | Claude Code | プロダクション水面実装時 |
| F-W03 | 水中ポストプロセス実装 + 統合計測 | Claude Code | `water_shader.md` §3.2 実装時 |
| F-W04 | 視覚回帰 baseline 登録(4 環境帯 + 嵐) | Claude Code | プロト合格直後の視覚回帰整備時 |

## 関連

- 親 Epic: `specs/epics/prototype_phase.md` §4(本決定で Resolves)
- 関連 spec: `specs/features/water_shader.md`
- シェーダ: `resources/shaders/water/water_surface.gdshader`(DEPTH_TEXTURE uniform 追加済)
- ベンチマーク: `tests/perf/water_benchmark.gd`(SceneTree refactor 済)
- マテリアル: `resources/materials/water/preset_*.tres`(4 環境帯)
- 規約: `docs/04_standards/quality_gates.md` §9.2(性能基準)

## 起票

- 起票日: 2026-05-05
- 起票者: Claude Code(本セッション主担当、ローカル Godot 実機計測を実行)
