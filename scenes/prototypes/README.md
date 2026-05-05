# プロトタイプシーン

本ディレクトリは `specs/epics/prototype_phase.md` に従い、3 つの主要技術リスクを検証するためのプロトシーンを集約する。

## 構成

| プロト | シーン | 主要スクリプト | 検証 spec |
|---|---|---|---|
| 水面・水中 | `water/water_test.tscn` | `water/water_test_controller.gd` | `specs/features/water_shader.md` |
| 浮体物理 | `floating/floating_physics_test.tscn` | `src/gameplay/building/floating_node.gd`、`floating/water_field.gd` | `specs/features/building_system.md` |
| マルチプレイ | `multiplayer/multiplayer_test.tscn` | `src/networking/network_manager.gd`、`multiplayer/*` | `specs/features/multiplayer_session.md` |

## 起動方法(エディタ)

1. Godot 4.6.2 でプロジェクトを開く(`docs/02_services/version_policy.md` §9.1)
2. 上記いずれかの `.tscn` を開き F6(Run Current Scene)

## 起動方法(ヘッドレス / ベンチマーク)

```sh
# 水面ベンチマーク(JSON レポート出力)
godot --headless -s res://tests/perf/water_benchmark.gd

# 浮体物理ストームシナリオ(5 分検証、デフォルト 100 個)
godot --headless -s res://tests/scenarios/building/storm_collapse_test.gd

# マルチプレイ統合テスト(GdUnit4 経由)
godot --headless -s res://addons/gdUnit4/runtest.gd -a res://tests/scenarios/multiplayer/
```

## マルチプレイ ローカル動作確認

GodotSteam GDExtension を導入する前は **ENet ループバック** で動作する。

1. 2 つの Godot インスタンスを起動(同じプロジェクト)
2. シーン 1 で「Host」ボタン
3. シーン 2 で「Join」ボタン(アドレス空欄 = 127.0.0.1)
4. 両シーンで矢印キー / WASD でプレイヤーが動くこと、相手のプレイヤーが見えることを確認

GodotSteam 導入後は `NetworkManager.backend = STEAM` でフレンド招待経由に切替予定(version_policy.md §9.1)。

## 既知の TODO(プロト本実装で消化)

- [ ] 水面シェーダの SSR / 屈折(現状: 深度ベースカラーミックス + 簡易フレネルのみ)
- [ ] 水中ボリューメトリックポストプロセス(別シェーダで追加予定)
- [ ] 浮体物理 250 / 500 のスケール検証(`physics_spawner.gd` の `spawn_count` で切替)
- [ ] 構造的整合性の連結処理(現状: 第 1 列を foundation 扱い、隣接探索ロジック未実装)
- [ ] GodotSteam Lobby 統合(GDExtension インストール後)
- [ ] 視覚回帰 baseline(各プロトの代表フレームを `tests/visual/baseline/` へ)

## 採否決定

各プロトの完了条件と代替プランは `specs/epics/prototype_phase.md` 各節を参照。
完了時の採否決定は `pipeline/decisions/2026-MM-DD_<proto>_result.md` に必ず記録する。
