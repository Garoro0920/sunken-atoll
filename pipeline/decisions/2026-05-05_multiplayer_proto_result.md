# 2026-05-05 マルチプレイプロト実測結果 — PARTIAL PASS

## 状態

- **Accepted**(部分達成)
- 親 Epic `specs/epics/prototype_phase.md` §6 を **Partial Resolves**
- 主要 DoD(4 接続成功率、切断検知、再接続)の検証は **多プロセス実行体制** が必要 — 本セッションでは未実施

## 実行環境

| 項目 | 値 |
|---|---|
| Godot | 4.6.2.stable.official.71f334935 |
| GdUnit4 | v6.1.3(local addon、CI 同期版) |
| Renderer | Vulkan / Forward+(GdUnit4 実行時)、headless |
| ネットワーク基盤 | Godot 標準 ENet(GodotSteam GDExtension は MVP 未統合) |

## 計測結果

GdUnit4 v6.1.3 経由 + 既存 PO 実測(`reports/report_1`)を統合:

### ✅ 成功

| テスト | 場所 | 結果 | 所要 |
|---|---|---|---|
| `test_host_starts_with_local_peer` | `tests/integration/networking/replication_basic_test.gd` | PASS | 5 ms |
| `test_join_without_server_fails_gracefully` | 同上 | PASS | 3 ms |

→ NetworkManager の **基本 API 表面が正常動作**:
- `host_server()` で ENet host 起動 + local peer (id=1) 確立
- `join_server()` でクライアント peer 作成、リッスナーなしでも graceful fail
- `disconnect_from_session()` のクリーンアップ

### ❌ 失敗(テスト設計の限界)

| テスト | 場所 | 結果 | 所要 |
|---|---|---|---|
| `test_4_clients_can_connect` | `tests/scenarios/multiplayer/connect_4players_test.gd` | FAIL(expected 4 peers, got 1) | 30 sec |
| `test_client_disconnect_is_detected` | `tests/scenarios/multiplayer/disconnect_reconnect_test.gd` | FAIL(expected 2 peers, got 1) | 30 sec |

#### 失敗の根本原因

**Godot のグローバル `multiplayer` peer は SceneTree 単位で 1 つしか保持できない**(`SceneTree.multiplayer_peer = peer` は最後の代入で上書き)。テストは:
1. host_server() でホスト peer を `multiplayer.multiplayer_peer` に設定
2. 続けて client_a の join_server() を同じ SceneTree 上で呼ぶと、host peer が **client peer に上書き** され、host が消失
3. 結果的に「peer 1 のみ存在する」状態で時間切れ

これは **テストの設計上の限界** であり、`NetworkManager` 実装自体の不具合ではない。

#### 正しい多 peer 検証手段

A. **多プロセス実行**: 4 つの Godot プロセスを並列起動し、ENet ループバック接続を確立
B. **per-node MultiplayerAPI**: 各クライアントを独立した SubViewport / 子 SceneTree に配置(複雑、Godot 4 で特殊用途)
C. **手動テスト**: PO がエディタ 4 インスタンスを起動して接続検証(MVP 段階で十分)

本セッションは A/B いずれも実装範囲外、C は PO 操作のためまだ未実施。

## 採否判定

`specs/epics/prototype_phase.md` §6.4 採否決定軸との対比:

| 基準 | 要求値 | 実測 | 判定 |
|---|---|---|---|
| 4 人ホスト型接続が **ローカル + Steam フレンド招待** で成立 | 成立 | ローカル単一プロセス: テスト設計限界で未検証 / Steam: MVP 未統合 | ⏳ 多プロセス検証要 |
| 接続成功率 > 95%(20 試行) | > 95% | 単一プロセスでは不可 | ⏳ 同上 |
| セッション開始から全員参加まで 30 秒以内 | ≤ 30 sec | 同上 | ⏳ 同上 |
| 切断検知 5 秒以内 | ≤ 5 sec | 同上 | ⏳ 同上 |
| 再接続成功率 > 95% | > 95% | 同上 | ⏳ 同上 |
| RTT 200/400 ms / loss 5% シミュレーション緑 | 緑 | 環境構築未実施(clumsy/netem) | ⏳ CI ジョブ整備時 |
| 帯域: クライアント上り 100 KB/s 以下、下り 300 KB/s 以下 | ≤ 上記 | 計測されていない | ⏳ 多プロセス検証時 |

### 判定: PARTIAL PASS

合格根拠:
- **NetworkManager 基本 API が正常動作**(host/join/disconnect の API 表面が機能)
- ENet バックエンドの正しい初期化、graceful failure handling 確認

未達根拠:
- **多 peer スケーリングテストが本セッション環境で実施不能**(Godot 単一プロセス制約)
- DoD §6.4 の本質基準(4 接続成立、切断検知、再接続)が **客観計測未済**

代替プラン採用判断: 部分的に必要(`prototype_phase.md` §6.4 代替プラン)。
- A(同期頻度引下げ): 多 peer テスト後に判定
- B(AOI フィルタ): 同上
- C(GodotSteam → ENet fallback): MVP 段階で ENet 採用済 = 既に C 状態
- D(2 人制限ストレッチ): 多 peer 検証次第

## 結果(期待される効果と現状)

- 基本 API レベルで動作確認 → MVP 実装の **NetworkManager クラスはこのまま使用可能**
- 多 peer 検証は別途 PO 手動テスト or 多プロセス CI ジョブ整備で実施

## 引き換えのリスクと残存事項

| リスク | 対策 |
|---|---|
| 多プロセス未検証 → 4 接続が実プレイで破綻する可能性 | F-M01 で PO 手動テスト、F-M02 で多プロセス CI 整備 |
| GodotSteam Lobby 未統合 → Steam フレンド招待動作未検証 | F-M03 で MVP 実装時に統合 + テスト |
| 同期破綻挙動(RTT 200/400ms / loss 5%)未検証 | F-M04 で clumsy / netem ジョブ整備 |
| 単一プロセスでは設計上 2 peer 以上の併存不可 | テスト戦略を多プロセス化 or per-node MultiplayerAPI 化 |

## フォロー

| # | 作業 | 担当 | トリガ |
|---|---|---|---|
| F-M01 | PO 手動 4 インスタンス接続テスト(2 人 → 4 人段階的に) | PO | プロト合格の最終確認時 |
| F-M02 | 多プロセス起動の CI ジョブ追加(Linux で 4 プロセス並列、ENet ループバック) | Claude Code | CI 拡張時 |
| F-M03 | GodotSteam GDExtension 統合 + Steam Lobby + フレンド招待テスト | Claude Code | MVP マルチプレイ実装時 |
| F-M04 | clumsy(Win)/ netem(Linux)による RTT・loss シミュレーション CI ジョブ | Claude Code | CI 拡張時 |
| F-M05 | 失敗テストの設計修正(多プロセス前提の expected behavior に書換、または skip マーク + 注記) | Claude Code | F-M02 完了後または PO 指示で |

## 結論

NetworkManager の **API 設計は妥当** で、シングルプロセス基本テストは緑。
**多 peer スケーリングは本セッション範囲外** であり、MVP 実装時または PO 手動テストで検証必須。

部分達成のため、本プロトを「完全合格」扱いにせず **PARTIAL PASS** とし、F-M01〜F-M05 を併発フォローとして登録する。

## 関連

- 親 Epic: `specs/epics/prototype_phase.md` §6(本決定で Partial Resolves)
- 関連 spec: `specs/features/multiplayer_session.md`
- NetworkManager: `src/networking/network_manager.gd`
- テスト: `tests/integration/networking/replication_basic_test.gd`(PASS)、`tests/scenarios/multiplayer/`(設計修正候補)
- 既存 PO 報告: `reports/report_1/results.xml`(replication_basic_test 2 PASS)
- バージョン: `docs/02_services/version_policy.md` §9.1(GdUnit4 v6.1.3、GodotSteam 4.18.1 — 後者 MVP 未統合)
- 規約: `docs/04_standards/quality_gates.md` §9.2

## 起票

- 起票日: 2026-05-05
- 起票者: Claude Code(本セッション主担当、ローカル GdUnit4 v6.1.3 で実行)
