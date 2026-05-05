# Epic: プロトタイプフェーズ(技術検証)

| 項目 | 内容 |
|---|---|
| 状態 | Draft(承認待ち) |
| 親 | `specs/game_design_document.md` §7、§8 |
| 起票日 | 2026-05-05 |
| 想定期間 | 4 週(2 スプリント想定、調整可) |
| 関連決定 | `pipeline/decisions/2026-05-05_gdd_initial.md`、`pipeline/decisions/2026-05-05_version_proposal.md` |
| 関連規約 | `docs/04_standards/quality_gates.md` §9、`docs/05_claude_code/task_decomposition_policy.md` |

## 1. 目的

MVP 実装に着手する前に、本作の **3 つの主要技術リスク**(GDD §7.7)を最小実装で検証し、採否を確定する。

検証対象:
1. **水面シェーダ + 水中ボリューメトリック**(`specs/features/water_shader.md`)— 性能・品質
2. **浮体物理の安定性**(`specs/features/building_system.md`)— Jolt + 多数オブジェクト
3. **4 人マルチプレイ接続**(`specs/features/multiplayer_session.md`)— GodotSteam + 同期方式

各検証で **採否決定軸を明示** し、不合格時の代替プランも事前に定義する。

## 2. 受入基準(Epic レベル DoD)

- [ ] 3 プロトすべてに採否判定が下されている(各個別 DoD を参照)
- [ ] 各プロトの結果が `pipeline/decisions/` に意思決定ログとして残されている
- [ ] 不合格プロトについては **代替プラン** が記録されている
- [ ] 性能ベンチマーク値が `docs/04_standards/quality_gates.md` §9.2 の絶対下限と比較されている
- [ ] 本 Epic 完了後、MVP 実装計画(別 Epic)が起票されている

## 3. 前提条件(Epic レベル DoR)

- [ ] バージョン採択 A 群が PO 承認済(`pipeline/decisions/2026-05-05_version_proposal.md` F-V01)
- [ ] `docs/02_services/version_policy.md` マトリクスに A 群が転記済(F-V02)
- [ ] プロジェクトスカフォールド整備済(完了)
- [ ] CI 最低限(import + lint)動作確認(本 Epic 内で構築可)

## 4. プロト 1: 水面シェーダ + 水中ボリューメトリック

### 4.1 目的
本作の世界観中核である水面・水中表現が **目標 GPU 予算内で要求品質を満たすか** 検証する。

### 4.2 スコープ
- 水面: Gerstner 波 ×3 重ね合わせ、SSR ベース反射、深度依存屈折、浅瀬透過、白波
- 水中: 距離フォグ、ライトシャフト、色調・歪みポストプロセス、ヘッドライト散乱
- 環境帯切替: 浅瀬 / 半水没都市 / 沿岸遺跡 / 深海帯のパラメータプリセット
- カメラの水面跨ぎ: 簡易処理(完全な部分水中表示はスコープ外)

### 4.3 配置
- `scenes/prototypes/water_test.tscn`(検証シーン)
- `resources/shaders/water/`(シェーダ)
- `resources/materials/water/`(マテリアル + 環境帯プリセット)
- `tests/perf/water_benchmark.gd`(ベンチマーク)
- `tests/visual/scenarios/water/`(視覚回帰テストシーン)

### 4.4 採否決定軸
**合格条件(全て満たす)**:
- デスクトップ標準 1080p で平均 60 FPS、1% low 50 FPS 以上
- Steam Deck 720p で平均 40 FPS 以上
- 水面 GPU 予算: 1.5 ms 以内(デスクトップ標準)、2.0 ms 以内(Steam Deck)
- 水中 GPU 予算: 1.0 ms 以内(デスクトップ標準)、1.5 ms 以内(Steam Deck)
- Vision 視覚判定で「ピンク・真っ黒・縞・Z-fighting なし」(`testing_workflow.md` §8)

**不合格時の代替**:
- A: シェーダ簡略化(SSR 削除、屈折削除、波数削減)
- B: Renderer Mobile への切替検討(Forward+ → Mobile)
- C: 反射を **動的キューブマップ**(低更新頻度)へ置換
- D: 環境帯ごとの品質階層(沿岸は高品質、深海は遠景フォグ依存)

### 4.5 受入基準(プロト DoD)
- [ ] 4 環境帯のスクリーンショットが `tests/visual/baseline/water/` に登録
- [ ] ベンチマーク値が CI に記録される(`build/test_reports/perf/water.json`)
- [ ] 採否決定が `pipeline/decisions/2026-MM-DD_water_proto_result.md` に記録
- [ ] 不合格部分があれば代替プランが採択され `water_shader.md` 仕様が更新

### 4.6 期間
**1 週間**(検証 4 日 + 文書化・調整 1 日 + 余白 2 日)

---

## 5. プロト 2: 浮体物理の安定性

### 5.1 目的
Jolt 物理(Godot 4.6 既定)で **多数の浮体接続構造が嵐イベント下でも崩壊しないか** 検証する。

### 5.2 スコープ
- 浮体プリミティブ(キューブ + 浮力体)を 100 / 250 / 500 個配置した接続構造
- 波動シミュレーション(プロト 1 の水面と同期)による揺動
- 嵐イベント(波振幅 / 風速の急変)
- 構造的整合性チェック(支持を失った部材の崩壊判定)
- 静的化最適化(動かない部材を static body へ昇格する仕組み)

### 5.3 配置
- `scenes/prototypes/floating_physics_test.tscn`
- `src/gameplay/building/floating_node.gd`(浮体ノード基底)
- `src/gameplay/building/structural_integrity.gd`(整合性判定)
- `tests/perf/floating_physics_benchmark.gd`
- `tests/scenarios/building/storm_collapse.gd`(嵐イベントテスト)

### 5.4 採否決定軸
**合格条件(全て満たす)**:
- 500 浮体接続構造、波動 + 嵐イベント 5 分連続で **意図しない倒壊・破裂・物理発散なし**
- 平均 FPS: デスクトップ標準 1080p で 60 以上(物理 + 描画合算)
- 物理 tick あたり 16.6 ms 以内(60 Hz 維持)
- 静的化最適化で動かない部材の物理コストが 1/10 以下になる
- 嵐解除後、構造が安定状態へ戻る

**不合格時の代替**:
- A: 浮力モデル簡略化(個別計算 → エリア平均)
- B: 接続を強剛体ジョイントから distance constraint へ
- C: 大型構造物の物理を完全静的化し、嵐影響は視覚のみ(揺れ表現)
- D: 浮体上限を 250 まで引下げ、500 はストレッチへ

### 5.5 受入基準(プロト DoD)
- [ ] ベンチマーク値が CI に記録される
- [ ] シナリオテスト「嵐 5 分連続で崩壊なし」が緑
- [ ] 採否決定が `pipeline/decisions/2026-MM-DD_floating_proto_result.md` に記録
- [ ] `building_system.md` 仕様の §3.7 「拠点規模上限」を実測値で更新

### 5.6 期間
**1.5 週間**(検証 7 日 + 調整 2 日 + 余白 2 日)

---

## 6. プロト 3: 4 人マルチプレイ接続

### 6.1 目的
GodotSteam ベースのホスト型セッションで **4 人接続 + 状態同期 + 切断/再接続が劣悪ネット条件下でも成立するか** 検証する。

### 6.2 スコープ
- Steam Lobby + P2P 接続(GodotSteam 4.18.1)
- 簡易プレイヤー(移動 + ジャンプ)の位置・姿勢同期(20 Hz、補間)
- 簡易インベントリ(イベント駆動同期)
- 簡易採集アクション(権威判定)
- 切断・再接続(キャラ・インベントリ復元)
- ネットワーク条件シミュレーション(clumsy / netem)

### 6.3 配置
- `scenes/prototypes/multiplayer_test.tscn`
- `src/networking/lobby.gd`、`src/networking/replication.gd`、`src/networking/authority.gd`
- `scenes/ui/lobby_test.tscn`
- `tests/scenarios/multiplayer/connect_4players.gd`
- `tests/scenarios/multiplayer/disconnect_reconnect.gd`
- `tests/integration/networking/replication_basic.gd`
- CI ジョブ: `network_conditions.yml`(RTT / loss 注入)

### 6.4 採否決定軸
**合格条件(全て満たす)**:
- 4 人ホスト型接続が **ローカル + Steam フレンド招待** で成立
- 接続成功率 > 95%(20 試行)
- セッション開始から全員参加まで 30 秒以内
- 切断検知 5 秒以内、再接続成功率 > 95%
- 同期遅延: RTT 200ms 環境で目立つ補正破綻なし
- RTT 400ms / loss 5% 環境で許容劣化(プレイ可能なレベル)
- 帯域: クライアント上り 100 KB/s 以下、下り 300 KB/s 以下

**不合格時の代替**:
- A: 同期頻度引下げ(20 Hz → 10 Hz)+ 補間強化
- B: AOI フィルタを早期実装し、遠方プレイヤーの同期を間引き
- C: GodotSteam → 標準 ENet にフェイルバック検討
- D: 同時接続数を 2 人に制限してリリース、4 人はストレッチへ

### 6.5 受入基準(プロト DoD)
- [ ] ローカル 4 インスタンス起動でセッション成立
- [ ] Steam フレンド招待での接続が動作(最低 1 回手動確認)
- [ ] 切断/再接続シナリオテスト緑
- [ ] CI に同期テストジョブ追加(RTT 200ms / 400ms + loss 5%)
- [ ] 採否決定が `pipeline/decisions/2026-MM-DD_multiplayer_proto_result.md` に記録
- [ ] `multiplayer_session.md` 仕様の §3.4 帯域実測値を更新

### 6.6 期間
**1.5 週間**(検証 7 日 + 文書化・CI 整備 2 日 + 余白 2 日)

---

## 7. 並列化と全体スケジュール

各プロトは触るレイヤが異なり **並列実施可能**(`task_decomposition_policy.md` §6)。

```
週 1     週 2     週 3     週 4
[==============] プロト 1: 水面・水中
       [=======================] プロト 2: 浮体物理
              [================] プロト 3: マルチプレイ
                                 [===] 統合判断・MVP 計画起票
```

### 推奨同時並走
- プロト 1 と 2 は同じ週で並走(別ファイル群)
- プロト 1 完了後、プロト 1 の水面パラメータをプロト 2 の浮体テストへ流用
- プロト 3 は週 2 開始(他 2 つの基盤に依存しない)

### Claude Code への引渡し時の注意
- 各プロトは独立タスク化し並列実装
- 触ってよいパスをプロトごとに明示(`task_decomposition_policy.md` §12)
- 結果ログは各プロト完了時に必ず `pipeline/decisions/` へ

---

## 8. 統合判断(本 Epic 終了時)

3 プロトの結果を集約し、以下を確定する:

1. **MVP 実装可否**: 3 プロト合格 → MVP 着手 / 不合格部分あり → 仕様調整 + 再判定
2. **品質ゲート閾値の見直し**: 実測値で `quality_gates.md` §9 を更新する必要があるか
3. **GDD §7.7 リスクの再評価**: 残存リスクを更新
4. **MVP Epic の起票**: `specs/epics/mvp_implementation.md`(プロト合格を前提に分解)

統合判断結果は `pipeline/decisions/2026-MM-DD_prototype_phase_result.md` に記録。

---

## 9. リスク

| リスク | 発生時の対応 |
|---|---|
| プロト 1 が大幅劣化、目標 FPS 未達 | 代替プラン A〜D を順次試行、最終的にビジュアル品質ターゲット引下げ判断は CD + PO |
| プロト 2 で物理発散が頻発 | Jolt 設定再調整 → 簡略化モデル → 部分静的化、最終手段は浮体上限引下げ |
| プロト 3 で Steam Lobby が想定通り動かない | ENet フォールバック検討、GodotSteam Issue Tracker 確認、最悪専用サーバ早期検討 |
| 期間超過(各プロト 1.5 週超え) | スコープ縮退判断 → CD + PO に提示 |
| Godot 4.6.2 自体のバグ起因 | 4.6.1 / 4.6 へのダウングレード可能性を保留(version_policy 改訂) |

## 10. 完了後の次の一歩

1. 統合判断結果を `pipeline/decisions/` に記録
2. `specs/epics/mvp_implementation.md` を起票(MVP 全体の分解計画)
3. CI 拡充(視覚回帰本格運用、性能ベンチマーク継続実行)
4. 品質ゲート閾値の実測値による更新

## 11. 参照

- GDD: `specs/game_design_document.md` §7、§8
- 個別 spec: `specs/features/water_shader.md`、`specs/features/building_system.md`、`specs/features/multiplayer_session.md`
- 規約: `docs/04_standards/quality_gates.md`、`docs/03_workflows/testing_workflow.md`、`docs/06_operations/ci_cd_pipeline.md`
- 分解ポリシー: `docs/05_claude_code/task_decomposition_policy.md`
- 親決定: `pipeline/decisions/2026-05-05_gdd_initial.md`、`pipeline/decisions/2026-05-05_version_proposal.md`
