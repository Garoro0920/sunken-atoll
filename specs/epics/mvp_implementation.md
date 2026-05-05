# Epic: MVP 実装(Sunken Atoll)

| 項目 | 内容 |
|---|---|
| 状態 | Active(2026-05-05 起票、プロト合格判定 `pipeline/decisions/2026-05-05_prototype_phase_result.md` 後に開始) |
| 親 GDD | `specs/game_design_document.md` §8.1(MVP 範囲) |
| 起票日 | 2026-05-05 |
| 想定期間 | 12 週(3 スプリント想定、調整可) |
| 関連決定 | `2026-05-05_prototype_phase_result.md`(プロト統合判断)、`2026-05-05_initialization_complete.md`(基盤確定) |

## 1. 目的

GDD §8.1「MVP に含める」の全機能を実装し、**4 人協力プレイで「漂着 → T2 拠点構築 → 沿岸遺跡踏破」を 1 セッションで完遂可能** な状態にする。プロト合格を基盤として、9 機能 spec(`specs/features/`)を統合する。

## 2. MVP スコープ確認(GDD §8.1 再掲)

### 2.1 含める
- 浅瀬・半水没都市・沿岸遺跡の **3 環境帯**
- 自由潜水 + 簡易ダイビングギア(`survival_balance.md`)
- 筏 / 帆船 / 動力船(`boat_navigation.md`)
- T1〜T2 拠点ティア(`building_system.md`)
- 海賊小集団 1 種、海生危険生物 2 種(`combat.md`)
- **4 人協力プレイ(ホスト型)**(`multiplayer_session.md`)
- 派閥 1〜2 + 簡易交易(`faction.md`)
- メインストーリー導入のみ
- LLM NPC(主要 3 種)(`ai_npc_dialog.md`)
- 動的潮汐 + 嵐イベント(`day_night_cycle.md`)
- 水面 / 簡易水中レンダリング(`water_shader.md`)

### 2.2 含めない(GDD §8.3)
- PvP / F2P 課金 / ターン制 / マイクロトランザクション
- 深海帯・潜水艇・専用サーバ・コンソール展開・Web 配信

## 3. 受入基準(Epic レベル DoD)

### 3.1 ゲームプレイ(`docs/00_overview/project_charter.md` 成功基準より)
- [ ] 4 人協力で「漂着 → T2 拠点構築 → 沿岸遺跡踏破」が 1 セッション完遂可
- [ ] クローズドプレイテストで「もう 1 セッション続けたい」回答率 70% 以上

### 3.2 技術品質(`docs/04_standards/quality_gates.md` §9.2 / §9.3)
- [ ] G2 ゲートすべて緑(視覚回帰 SSIM ≥ 0.95、性能回帰 < 5%、テストカバレッジ ≥ 50%)
- [ ] 同期: RTT 200ms 緑、RTT 400ms / loss 5% 許容劣化
- [ ] 描画: デスクトップ標準 1080p 60 FPS / 1% low 50 FPS、Steam Deck 720p 40 FPS
- [ ] 安定性: 1 セッション 2h でクラッシュ・進行不能・致命同期破綻 0 件

### 3.3 IP / ガバナンス
- [ ] 主要意匠の F-05C(US/EU/JP 再検索)実施済
- [ ] AI 倫理ガイドライン(`docs/07_governance/ai_ethics.md`)準拠
- [ ] LICENSE 著作権者最新化(F-CR-01 学校 IP 規定確認反映)

### 3.4 ドキュメント / ビルド
- [ ] 9 機能 spec の DoD すべて完了
- [ ] CI G2 / G3 緑(リリースビルド + 配布物サイズ閾値内)
- [ ] リリースノート ドラフト

## 4. 機能群と依存関係

```
[基盤層]
  day_night_cycle.md    (時刻 / 天候 / 潮汐 / 風) ◀────┐
  water_shader.md       (海面・水中レンダ)             │
  survival_balance.md   (HP/空腹/喉/体温/酸素/汚染)   │
  multiplayer_session.md(4 人ホスト型ネットワーク)    │
                         │                             │
[ゲームプレイ層]         ▼                             │
  combat.md             (近接/遠距離/設置)             │
  building_system.md    (浮体拠点 + 構造的整合性) ─────┤
  boat_navigation.md    (筏/帆/動力船 + 役割分担) ────┤
                         │                             │
[コンテンツ層]           ▼                             │
  faction.md            (海賊 + 孤立島民 + 動的評判)  │
  ai_npc_dialog.md      (LLM 駆動主要 NPC) ────────────┘
                         │
                         ▼
[統合層]
  - メインストーリー導入(別 spec 起票候補: `story_intro.md`)
  - 3 環境帯マップ構築(別 spec 起票候補: `levels.md`)
  - クローズドプレイテスト
```

## 5. スプリント分割案(調整前提)

### Sprint 1(週 1〜4): 基盤層 + 単体ゲームプレイ
- `day_night_cycle.md` 実装(時刻 + 天候 + 潮汐 + 風の同期基盤)
- `water_shader.md` MVP 実装(SSR / 屈折 / 水中ポストプロセス追加)
- `survival_balance.md` 実装(6 状態 + データ駆動バランス)
- `building_system.md` T1 実装(基本浮体拠点)
- `multiplayer_session.md` Steam Lobby + 4 人接続(F-M01 PO 手動検証含む)
- F-M02 多プロセス CI ジョブ整備
- ✅ Sprint 1 DoD: シングルプレイで「漂着 → T1 拠点」完遂

### Sprint 2(週 5〜8): ゲームプレイ層 + マルチ統合
- `combat.md` 実装(銛・斧・弓・スリング + 設置タレット)
- `building_system.md` T2 実装 + 構造的整合性連結処理(F-F03)
- `boat_navigation.md` 実装(3 船種 + 役割分担)
- マルチプレイ統合(全機能の権威同期確認)
- F-W02 / F-F01 プロファイラ計測 → 必要なら最適化
- ✅ Sprint 2 DoD: 4 人協力で「T2 拠点構築」完遂

### Sprint 3(週 9〜12): コンテンツ + 統合 + リリース準備
- `faction.md` 実装(海賊 + 孤立島民 + 動的評判)
- `ai_npc_dialog.md` 実装(主要 3 NPC、Anthropic Claude 統合)
- 3 環境帯マップ構築
- メインストーリー導入実装
- F-W01 / F-F05 Steam Deck 実機計測
- F-CR-01 学校 IP 規定確認 + LICENSE 最新化
- F-05C 主要意匠の商標再検索
- クローズドプレイテスト(4〜8 名)
- リリース候補ビルド + G3 通過
- ✅ Sprint 3 DoD: §3 受入基準全項目達成、リリース候補完成

## 6. プロトから持ち越す課題(集約)

`prototype_phase.md` 各プロトから持ち越されたフォロー項目:

### 水面プロト由来
- F-W01: Steam Deck 実機水面ベンチ(Sprint 3)
- F-W02: Frame Profiler 水面 GPU 単独時間計測(Sprint 2)
- F-W03: 水中ポストプロセス実装 + 統合計測(Sprint 1)
- F-W04: 視覚回帰 baseline 登録(Sprint 1 末)

### 浮体物理プロト由来
- F-F01: 47 ms スパイク要因調査(Sprint 1〜2)
- F-F02: 静的化最適化実装(Sprint 2)
- F-F03: 連結ロジック本実装(Sprint 2)
- F-F04: 視覚整合確認 + baseline(Sprint 1 末)
- F-F05: Steam Deck 浮体ベンチ(Sprint 3)

### マルチプレイプロト由来 ⚠ 高優先
- **F-M01: PO 手動 4 接続テスト**(Sprint 1 着手直後・必須)
- F-M02: 多プロセス CI ジョブ整備(Sprint 1)
- F-M03: GodotSteam 統合 + Lobby + フレンド招待(Sprint 2)
- F-M04: clumsy / netem ネット条件 CI(Sprint 2)
- F-M05: 失敗テストの設計修正(F-M02 完了後)

### 初期化由来
- F-CR-01: 神戸電子専門学校 IP 規定確認(配布前必須)
- F-05B: CN/KR 商標調査(アジア展開判断時のみ)
- F-05C: 主要意匠の US/EU/JP 商標再検索(意匠確定前)
- F-05D: リリース後 1 年再調査
- F-V03: C 群サービス採択(アート / 音響 / バックエンド工程到達時)

## 7. リスク管理

| リスク | 重大度 | 対策 |
|---|---|---|
| 多 peer マルチプレイが想定通り動かない | 高 | F-M01 を Sprint 1 序盤に必須化、ダメなら早期に GodotSteam 切替 |
| 9 spec 同時並行で技術的負債蓄積 | 中 | Sprint 単位で品質ゲート徹底、リファクタ専用タスクをスプリント末に |
| LLM API コスト想定超過 | 中 | `ai_npc_dialog.md` §3.6 のセッション内予算を Sprint 3 開始時点で実測 |
| Steam Deck 性能未達 | 中 | Sprint 3 早期に実機計測、ダメなら品質階層化 |
| プレイテスター手配難 | 中 | Sprint 2 末にテスター候補確保開始 |
| 学校 IP 規定が「学校所有」判定 | 中 | 配布前 F-CR-01 確認、判定により法的体裁を事前調整 |

## 8. 完了後の状態

Epic 完了で達成:
- ✅ MVP リリース候補ビルド完成
- ✅ G3(プレリリース)通過
- ✅ クローズドプレイテスト緑
- ✅ Sunken Atoll の **第一公開可能版** が手元にある状態

これにより以下のフェーズへ移行可能:
1. プレリリース配布(itch.io / Steam beta)
2. 内部 / 友人プレイテスト → フィードバック収集
3. 必要なら Sprint 4(改善 + バグ修正)
4. **本番リリース判定**(`docs/04_standards/quality_gates.md` G4)

## 9. 参照

- GDD: `specs/game_design_document.md` §8.1 / §8.3
- プロト統合判断: `pipeline/decisions/2026-05-05_prototype_phase_result.md`
- 機能 spec: `specs/features/`(survival_balance, water_shader, multiplayer_session, building_system, ai_npc_dialog, combat, faction, boat_navigation, day_night_cycle)
- 規約: `docs/04_standards/quality_gates.md` §9.2 / §9.3
- フロー: `docs/08_process/development_flow.md`
- 関連 Epic: `specs/epics/prototype_phase.md`(完了)、`specs/epics/concept_art_safe_zone.md`(BLOCKED 解除済)、`specs/epics/key_visuals.md`(別途起票予定)

## 10. 起票

- 起票日: 2026-05-05
- 起票者: Claude Code
- 後続: Sprint 1 着手指示時に詳細タスク分解 + TaskCreate
