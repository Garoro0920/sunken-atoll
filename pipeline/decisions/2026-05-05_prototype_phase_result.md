# 2026-05-05 プロトタイプフェーズ統合判断 — MVP 着手 GO

## 状態

- **Accepted**(統合判断完了、MVP 着手承認)
- 親 Epic `specs/epics/prototype_phase.md` を **Resolves**(Epic 完了)
- 後続: `specs/epics/mvp_implementation.md` を起票

## 文脈

`specs/epics/prototype_phase.md` で計画した 3 プロト(水面 / 浮体物理 / マルチプレイ)を本セッション内で実測完了。本決定は 3 結果を集約し **MVP 実装フェーズへの移行可否** を判定する。

## 各プロト個別結果(リファレンス)

| プロト | 結果 | 主指標 | 個別決定ログ |
|---|---|---|---|
| 水面シェーダ | **PASS** | 144 fps avg / 130 fps 1% low(要求 60/50 の 2.4〜2.6 倍) | `pipeline/decisions/2026-05-05_water_proto_result.md` |
| 浮体物理 | **PASS WITH CAVEAT** | 500 floats × 5 min: avg 16.67 ms(完璧 60 Hz)、max 47 ms スパイク 1 件 | `pipeline/decisions/2026-05-05_floating_proto_result.md` |
| マルチプレイ | **PARTIAL PASS** | 基本 API: 2/2 PASS / 多 peer スケーリング: テスト設計限界で未検証 | `pipeline/decisions/2026-05-05_multiplayer_proto_result.md` |

## 統合判断

### MVP 着手可否: **GO**

合格根拠(主要 3 リスク = GDD §7.7 への対応):

| GDD §7.7 高リスク項目 | プロト結果 | 残存リスク |
|---|---|---|
| 水面・水中シェーダの性能負荷 | RTX 4050 で大幅余裕(2.4 倍 +) | Steam Deck 実機計測のみ(MVP 終盤で対応可) |
| マルチプレイ同期の複雑性 | 基本 API 動作確認 / 多 peer 未検証 | MVP 実装中に 4 プロセス手動テストで漸進検証 |
| 浮体物理の安定性 | 500 floats × 5 min 完走、avg 完璧 | 単発スパイク要因解析(MVP 中) |

中リスク(LLM NPC レイテンシ、IP 類似性、海中オクルージョン)は別決定で個別対応済または進行中。

### 留保事項を MVP に持ち越す方針

**「条件付き合格」「部分合格」を含むがフェーズ進行を許可する** 判断とした理由:

1. **失敗ではなく未検証**: マルチプレイの未検証はテスト環境の制約であり、設計欠陥ではない
2. **数値的余裕**: 水面・浮体ともに「合格基準ギリギリ」ではなく **大幅余裕** ありの数値
3. **代替プラン保留**: `prototype_phase.md` §4.4 / §5.4 / §6.4 の代替プラン A〜D は **発動不要**
4. **MVP 中の継続検証**: 残課題は MVP 実装と並走で消化可能(F-W01〜F-M05)

これらを **MVP Epic で明示的フォロー化** することで透明性を保つ。

### 採用しなかった選択肢

- **プロトを再回す**(同じ条件で再計測): 数値が安定しており追加情報なし
- **代替プラン採用してプロト再設計**: 主要基準満たすため不要
- **MVP 着手延期**: 残リスクは MVP 並走で十分管理可、延期はスケジュールリスク
- **多プロセス CI 整備をプロト完了条件に追加**: 範囲拡大、MVP 実装中での整備に分割移譲

## 結果(期待される効果)

- **GDD §7.7 主要 3 リスクが「許容範囲」と判定** → 設計通り進行可
- プロト工程が予定どおり完了(`prototype_phase.md` §7 スケジュールの「統合判断・MVP 計画起票」マイルストーン到達)
- `specs/epics/mvp_implementation.md` を起票し、MVP 全機能の分解計画フェーズへ移行
- プロト過程で発見された GDScript 型エラー / シェーダ API 変更は実装段階で再発しない(修正済)

## 引き換えのリスク

本判断によって持ち越されるリスクと管理戦略:

| リスク | 影響 | 管理方針 |
|---|---|---|
| 浮体物理 47 ms スパイクの根本原因不明 | 中 | F-F01 で MVP 序盤にプロファイラ計測。再現性なければ無視可 |
| マルチプレイ多 peer 未検証 | **高** | F-M01(PO 手動 4 接続)を MVP 序盤の必須マイルストーンに設定 |
| Steam Deck 実機未検証 | 中 | F-W01 / F-F05 で MVP 終盤に実機検証 |
| GodotSteam 未統合 | 中 | F-M03 で MVP 中盤に統合 |

## フォロー

| # | 作業 | 担当 | 期限 |
|---|---|---|---|
| F-PP01 | `specs/epics/mvp_implementation.md` を起票(本決定と同時) | Claude Code | 本決定と同時 |
| F-PP02 | `specs/epics/prototype_phase.md` を archive 状態に更新(状態フィールドのみ、本文は履歴保持) | Claude Code | 本決定と同時 |
| F-PP03 | プロト由来の継続フォロー(F-W01〜F-W04、F-F01〜F-F05、F-M01〜F-M05)を MVP Epic の「持ち越し課題」セクションへ集約 | Claude Code | F-PP01 と同時 |
| F-PP04 | F-M01(PO 手動 4 接続テスト)を MVP 序盤の必須マイルストーンとして明示 | PO + Claude Code | MVP 着手直後 |

## 関連

- 親 Epic: `specs/epics/prototype_phase.md`(本決定で Resolves)
- 個別決定: `pipeline/decisions/2026-05-05_water_proto_result.md`、`...floating_proto_result.md`、`...multiplayer_proto_result.md`
- 後続 Epic: `specs/epics/mvp_implementation.md`(本決定の F-PP01 で起票)
- GDD: §7.7、§8.1
- 規約: `docs/04_standards/quality_gates.md` §9.2

## 起票

- 起票日: 2026-05-05
- 起票者: Claude Code(本セッション主担当、3 プロト実測 + 個別決定起票後の統合判断)
