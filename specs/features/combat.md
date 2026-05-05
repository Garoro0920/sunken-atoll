# Spec: 戦闘システム

| 項目 | 内容 |
|---|---|
| 状態 | Draft |
| 親 GDD | `specs/game_design_document.md` §4.2 / §1.3 |
| 起票日 | 2026-05-05 |
| 関連 spec | `survival_balance.md`、`multiplayer_session.md`、`building_system.md`(防衛設備) |

## 1. 目的

近接 / 遠距離 / 防御 / 設置物による戦闘を、**サバイバル文脈の従属要素**として実装する。戦闘は主役ではなく、資源獲得・拠点防衛・襲撃イベントの解決手段として位置付ける(GDD §4.2)。

## 2. ユーザストーリー

- プレイヤーとして、海賊と遭遇したときに戦闘か逃走を選択できる。
- 拠点防衛時に複数人で異なる方向を分担できる。
- 戦闘結果が資源・装備耐久・サバイバル状態へ波及することを実感したい。

## 3. 要件

### 3.1 武器カテゴリ

| カテゴリ | MVP | 例 | 主な特徴 |
|---|---|---|---|
| 近接 | ✓ | 銛、斧、ナイフ | スタミナ消費、射程短 |
| 遠距離 | ✓ | 弓、スリング | 弾薬要、再装填 |
| 改造火器 | ストレッチ | 改造拳銃、即席ライフル | 高威力、希少弾薬 |
| 設置物 | ✓ | トラップ、簡易タレット | 拠点防衛、設置時間 |
| 投擲 | ストレッチ | 燃焼瓶、煙幕 | 範囲効果 |

### 3.2 ダメージモデル

- 攻撃 = `base_damage × weapon_multiplier × stamina_factor × hit_zone_multiplier`
- 防御 = `defense_value × armor_durability_factor`
- 最終ダメージ = `max(0, attack - defense) × random(0.9, 1.1)`(乱数は権威側固定シード)
- ヒットゾーン: 頭(× 2.0)、胴(× 1.0)、四肢(× 0.7)

### 3.3 ヒットボックス / ハートボックス

- すべての攻撃可能エンティティに `Hitbox`(攻撃判定)と `Hurtbox`(被弾判定)ノードを設置
- レイヤ命名: `hitbox_player` / `hitbox_enemy` / `hurtbox_player` / `hurtbox_enemy`(`docs/04_standards/scene_standards.md` §11)
- `Area3D` ベース、シグナル `area_entered` で判定発火

### 3.4 戦闘状態機械

```
Idle → Aim/Charge → Strike → Recover → Idle
                       ↓
                    Hit (interrupt)
```

`AnimationTree` で実装、`survival_balance.md` のスタミナ系と連動。

### 3.5 マルチプレイ整合

- ダメージ判定は **ホスト権威**(`multiplayer_session.md` §3.3)
- クライアントは攻撃モーションを予測再生、命中判定はサーバ確定
- 矛盾発生時はサーバ判定を採用、クライアント側は補正

### 3.6 ゲームプレイ連動

| 事象 | 影響先 spec |
|---|---|
| 武器使用 | `survival_balance.md`(スタミナ) |
| 武器耐久消耗 | 別 spec(decay_durability、未起票) |
| 設置物建造 | `building_system.md` |
| ボス/海賊襲撃イベント | 本 spec + `faction.md`(海賊勢力) |
| 死亡時装備落下 | `survival_balance.md` §3.3、本 spec で拾得処理 |

### 3.7 非機能要件

- ヒット判定 1 回あたり CPU < 0.1 ms
- 同時戦闘エンティティ 16 体まで安定(MVP)
- 視覚: ヒット表現(パーティクル + サウンド + ヒットストップ)で視認性を確保

### 3.8 テスト観点

- 単体: ダメージ計算式(境界値)、ヒットゾーン乗数
- 統合: ヒットボックス × ハートボックス判定
- シナリオ:
  - プレイヤー vs 海賊 1 体での勝敗成立
  - 4 人で海賊 4 体襲撃イベントを撃退
  - 設置タレットによる防衛
- マルチプレイ: 命中判定の同期(クライアント予測 vs サーバ確定の整合)

## 4. 非要件 / スコープ外

- PvP モード(GDD §8.3 で除外)
- 死体の解体・剥ぎ取り(別 spec、ストレッチ)
- 弾道シミュレーション(MVP は直線判定 + 重力近似)
- ロックオンシステム(未採用方針)

## 5. 受入基準(DoD)

- [ ] 4 武器(銛・斧・弓・スリング)が動作
- [ ] ヒットボックス / ハートボックスが規約準拠で配置
- [ ] サーバ権威ダメージ判定がマルチプレイで動作
- [ ] シナリオテスト 3 種が緑
- [ ] パフォーマンス: 16 体同時で 60 FPS @1080p
- [ ] 視覚: ヒット表現の baseline 登録

## 6. 想定実装

- 配置: `src/gameplay/combat/`、`scenes/characters/weapons/`、`resources/data/weapons/`
- 触ってよいパス: 上記 + `tests/unit/combat/`、`tests/integration/combat/`、`tests/scenarios/combat/`
- 触らないパス: `src/networking/` 基盤(同期 API のみ利用)

## 7. リスクと未決事項

| リスク | 対策 |
|---|---|
| 武器バランスの長期調整 | データ駆動 + プレイテスト早期 |
| 死亡ペナルティ強度(GDD §9 Q-06)未確定 | プロト後 PO 判断、本 spec を改訂 |
| 同時 16 体の物理同期負荷 | AOI で遠方を間引き、`multiplayer_session.md` §3.3 |
| 非対称武器バランス(近接 vs 遠距離) | 役割分担で誘導(`faction.md` 連携) |

## 8. 参照

- GDD: §4.2、§1.3、§5.4
- 関連 spec: `survival_balance.md`、`multiplayer_session.md`、`building_system.md`、`faction.md`
- 規約: `docs/04_standards/scene_standards.md` §11、`docs/04_standards/asset_standards.md` §6
