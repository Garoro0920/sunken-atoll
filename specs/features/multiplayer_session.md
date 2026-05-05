# Spec: マルチプレイセッション

| 項目 | 内容 |
|---|---|
| 状態 | Draft |
| 親 GDD | `specs/game_design_document.md` §6 |
| 起票日 | 2026-05-05 |
| 関連 | `docs/02_services/service_catalog.md` L16、`docs/02_services/secrets_management.md` |

## 1. 目的

MVP 範囲(2〜4 人ホスト型)のマルチプレイセッションを成立させ、招待・参加・離脱・再接続・権威同期を信頼性ある形で提供する。専用サーバ対応はストレッチ。

## 2. ユーザストーリー

- プレイヤーとして、Steam フレンドを 1 クリックで招待しセッションを開始できる。
- プレイヤーとして、ホストが切断しても自分のキャラ・進捗を後で再開できる。
- 開発者として、ネットワーク条件をシミュレートしてテストできる。

## 3. 要件

### 3.1 トポロジ(MVP)

- ホスト型(リスニングサーバ): プレイヤー 1 名がホスト、他はクライアント
- ホストが権威(ワールド状態 / インベントリ / 戦闘判定)
- 採用候補ライブラリ: GodotSteam(Steam Lobby + P2P)、Godot 4 標準 MultiplayerAPI
- 専用サーバ・ホストマイグレーションはストレッチ(`docs/02_services/service_catalog.md` L16: Nakama / Edgegap)

### 3.2 セッション管理

| 機能 | MVP | 備考 |
|---|---|---|
| Steam フレンド招待 | ✓ | GodotSteam Lobby |
| 招待コード | — | 専用サーバ実装後 |
| 最大同時接続 | 4 人 | GDD §6.3 想定の下限 |
| ホスト切断時 | クライアント切断 + ローカル保存通知 | マイグレーションは MVP 外 |
| 再接続 | ホスト再起動後にプレイヤー復帰 | キャラ・インベントリ復元 |
| パスワード保護 | ✓ | Lobby メタデータ |

### 3.3 同期方式

- **権威**: ホスト
- **同期対象**:
  - プレイヤー位置・姿勢: 高頻度(20 Hz)、補間
  - インベントリ・装備: イベント駆動
  - ワールド状態(建築物・採集状態): イベント + 周期スナップショット
  - サバイバル状態: 権威算出、UI 表示用に低頻度同期(2 Hz)
  - 戦闘判定: 完全権威(クライアント予測なし、MVP)
- **AOI(Area of Interest)**: 同一エリア内のみフル同期、遠方は要約
- **決定論性**: 物理 tick 固定(`Engine.physics_ticks_per_second`)、乱数は権威側のみ

### 3.4 帯域要件

- クライアント上り: 30〜100 KB/s 目安
- クライアント下り: 100〜300 KB/s 目安
- RTT: ≤ 200ms 快適、≤ 400ms 許容

### 3.5 セキュリティ

- ホスト権威により基本的な改竄を抑制
- Lobby パスワード / Steam Friend Only モード
- 入力検証はホスト側で実施(クライアント送信値を信用しない)
- API キー類は **クライアントに同梱しない**(`docs/02_services/secrets_management.md` §5)

### 3.6 非機能要件

- セッション開始から全員参加まで 30 秒以内
- 切断検知は 5 秒以内
- 再接続成功率 > 95%(ロス 5% / RTT 200ms 環境)

### 3.7 テスト観点

- 単体: パケットシリアライズ、状態 diff 計算
- 統合: ローカル 2 インスタンス起動でセッション成立
- シナリオ: 4 人接続 → 同時行動 → 切断 → 再接続 が完遂
- ネットワーク条件テスト: clumsy / netem で RTT 200/400 ms、ロス 5% を CI ジョブで模擬
- パフォーマンス: 4 人接続時の CPU / 帯域

## 4. 非要件 / スコープ外

- ホストマイグレーション(MVP 外、ストレッチ)
- 専用サーバ + Edgegap デプロイ(MVP 外)
- 反チートシステム(基本的な権威モデルのみ)
- ボイスチャット(Steam の標準機能を案内、ゲーム内実装は MVP 外)

## 5. 受入基準(DoD)

- [ ] 4 人ホスト型セッションが Steam 経由で成立
- [ ] 切断 → 再接続でキャラ・インベントリ復元
- [ ] AOI / イベント同期によるトラフィック予算内
- [ ] ネットワーク条件下シナリオテスト緑(RTT 200/400 ms、ロス 5%)
- [ ] CI に同期テストジョブ追加
- [ ] セキュリティ: ホスト権威モデルでの入力検証実装

## 6. 想定実装

- 配置: `src/networking/`、`src/core/session/`、`scenes/ui/lobby.tscn`、`scenes/ui/connection_status.tscn`
- 触ってよいパス: 上記 + `tests/integration/networking/`、`tests/scenarios/multiplayer/`
- 触らないパス: `src/gameplay/` の挙動本体(同期は trait として注入)

## 7. リスクと未決事項

| リスク | 対策 |
|---|---|
| GodotSteam のバージョン適合 | `version_policy.md` 確定後、互換性検証ジョブを設置 |
| NAT 越え失敗(Steam Relay 不可) | フォールバック手順を spec 改訂で追加 |
| 権威モデルの遅延感 | 移動はクライアント予測 + サーバ補正(MVP 後の改良候補) |
| プレイテスト人数確保 | プレイテスター手配(`project_charter.md` 想定体制) |

## 8. 参照

- GDD: §6
- `docs/02_services/service_catalog.md` L16
- `docs/02_services/secrets_management.md`
- `docs/03_workflows/testing_workflow.md`(シナリオテスト)
- `docs/06_operations/ci_cd_pipeline.md`(同期テストの CI 配置)
