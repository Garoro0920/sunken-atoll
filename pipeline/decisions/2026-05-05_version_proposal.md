# 2026-05-05 バージョン採択候補の提案(PO 承認待ち)

> **状態**: Proposed(承認前) — PO 承認後に `docs/02_services/version_policy.md` §9 のマトリクスへ転記してロックする。
> 本ファイル単独では `02_services/version_policy.md` を変更しない(`CLAUDE.md §9` 初期化要件 #1 は **PO 承認時点で消化**)。

## 文脈

CLAUDE.md §9 が定める初期化要件 #1「`02_services/version_policy.md` のバージョンマトリクスを埋める」が未消化のため本格作業に着手できない。本提案はその充足のための候補調査結果を提示する。

調査基準(`02_services/version_policy.md` §4 準拠):
- 公式リリースノート / GitHub Releases
- メンテナンス活発度
- セキュリティアドバイザリ
- 廃止予定・near deprecation 告知
- 本作要件(MVP: Steam デスクトップ、4 人協力、海洋表現、LLM NPC)との整合

## 提案バージョンマトリクス

### A 群: コア基盤(MVP 必須、即決すべき)

| カテゴリ | サービス/技術 | **提案版** | 採択理由 | 出典 |
|---|---|---|---|---|
| エンジン | Godot | **4.6.2** | 2026-04-01 リリース、最新安定。Jolt が既定 3D 物理化。LibGodot 等新機能。CG 向け改善多数 | [Godot Releases](https://github.com/godotengine/godot/releases)、[Godot 4.6 解説](https://digitalproduction.com/2026/01/28/godot-4-6-arrives-with-major-cg-friendly-updates/) |
| 物理 | Jolt | **Godot 4.6 同梱**(別途追加なし) | Godot 4.6 で既定 3D 物理化。AAA 製品実績(Horizon Forbidden West 由来)、GodotPhysics 比 2〜3x 性能 | [Using Jolt Physics 公式](https://docs.godotengine.org/en/latest/tutorials/physics/using_jolt_physics.html) |
| Steam 統合 | GodotSteam(GDExtension) | **4.18.1**(Steamworks SDK 1.64) | 2026-05-02 更新、Godot 4.6.2 動作確認済 | [GodotSteam Updates](https://godotsteam.com/blog/2026/03/27/updates-updates-updates/)、[GodotSteam GDExtension](https://store.godotengine.org/asset/godotsteam/godotsteam-gdextension/) |
| マルチプレイ基盤 | Godot 標準 MultiplayerAPI + GodotSteam Lobby | 上記同梱 | MVP はホスト型、専用サーバ不要(`specs/features/multiplayer_session.md` §3.1) | — |
| LLM(NPC + 開発支援) | Anthropic Claude Opus 4.7 | **claude-opus-4-7** | 現行最上位。1M context 利用可。プロジェクト規模に対し十分 | Anthropic 公式 |
| LLM Vision | Claude Opus 4.7(マルチモーダル) | 同上 | 視覚回帰判定で利用 | 同上 |
| LLM 廉価系(雑魚 NPC fallback 候補) | Claude Haiku 4.5 / Sonnet 4.6 | TBD | コスト感が見えてから決定 | 同上 |
| テスト | GdUnit4 | **v5.0.4** | Godot 4.6.x 対応の最新。**v6.0.x は Godot 4.5 専用で互換切れ — 採用不可** | [GdUnit4 Releases](https://github.com/MikeSchulze/gdUnit4/releases) |
| クラッシュ監視 | Sentry Godot SDK | **1.6.0** | 安定版、Windows / Linux / macOS / Android / iOS / Web 対応 | [Sentry Godot](https://github.com/getsentry/sentry-godot)、[Sentry 公式](https://docs.sentry.io/platforms/godot/) |

### B 群: 周辺基盤(MVP 必要だが採択は実装着手直前で可)

| カテゴリ | サービス/技術 | **提案版** | 採択理由 |
|---|---|---|---|
| .NET | **未採用**(GDScript のみ) | — | MVP では C# を採用しない方針。GDScript 統一でビルド・配布が単純化 |
| Python | **3.12.x**(ローカルロック) | パイプラインスクリプト用。安定 LTS 帯 |
| Node | **20.x LTS** | MCP / 配布スクリプト用。LTS で長期維持 |
| CI Runner OS | ubuntu-latest / windows-latest / macos-latest | GitHub Actions 標準 |
| 配布 CLI(itch.io) | butler | **broth から取得する rolling**(2026-01-28 以降) | itch.io 推奨方式、CI から `https://broth.itch.zone/.../LATEST` で固定 |
| 配布 CLI(Steam) | steamcmd | **rolling** | Valve がバージョン管理しない |

### C 群: 後続採択(MVP では未使用、または採用判断を生成工程で実施)

| カテゴリ | 採択方針 |
|---|---|
| 3D メッシュ生成(Tripo / Meshy / Rodin) | **アート生成工程開始時に PO + CD で決定**。MVP 直前の判断で十分 |
| テクスチャ生成(Stability / fal.ai / Scenario) | 同上 |
| HDRI(Blockade Skybox / Poly Haven) | 同上 |
| mocap(DeepMotion / Move.ai) | 同上、人型アニメ要件確定後 |
| 顔アニメ(Audio2Face) | リップシンク要件確定時 |
| BGM / SFX / TTS / アンビエント | 音響工程開始時 |
| バックエンド(Nakama / Edgegap) | **MVP では未採用**。ストレッチで専用サーバ採用時に Nakama Server 最新 + Edgegap |
| 翻訳(DeepL / Crowdin) | ローカライズ拡張時 |
| 分析(GameAnalytics 等) | リリース前 |
| MCP サーバ(Godot MCP Pro / GoPeak) | 開発自動化を強化する段階で評価 |

### D 群: 採用しない

| カテゴリ | 理由 |
|---|---|
| .NET | MVP は GDScript 単一言語で運用 |
| fastlane | モバイル展開が MVP 対象外 |
| FBX 主要採用 | 第一推奨は GLB(`asset_standards.md` §3) |

## 選定根拠の整理

### Godot 4.6.2 を選んだ理由
- **Jolt 物理が既定化**(本作要件: 浮体多数、`specs/features/building_system.md` §3.2 と整合)
- **Modern UI / 改善された反射**(本作要件: 水面表現、`specs/features/water_shader.md`)
- **LibGodot**(将来の埋込・自動化拡張に有利)
- 4.6.2 は 4.6 系の最新メンテナンス版でバグ修正集約済
- Godot 4.7 開発中だが MVP 期間中は 4.6 系で固定し、4.7 安定化後に評価

### GdUnit4 v5.0.4 を v6.0.x より優先する理由
- **v6.0.x は Godot 4.5 専用で破壊的変更あり、Godot 4.6 では動作しない**(明示的非互換)
- v5.0.4 は 2026-04 更新、Godot 4.6.x への対応を継続中

### Sentry Godot SDK 1.6.0
- 1.0 alpha が 2025 末、1.6.0 で十分な安定性
- 対象プラットフォーム(Windows / Linux / macOS)を全カバー

## 結果(採用時に期待される効果)

- 着手可否ブロッカー(`CLAUDE.md §9` 初期化要件 #1)が解消
- 各依存の最新安定が固定され、再現性が確保される
- Jolt 既定化により浮体物理プロト着手が容易
- LLM NPC は Claude Opus 4.7 で品質を確保しつつ、コスト見え次第 Sonnet/Haiku への切替判断が可能

## リスクと引き換え

| リスク | 影響 | 緩和策 |
|---|---|---|
| Godot 4.6.x で Jolt の浮体物理が想定通り安定するか未検証 | 中 | プロト工程(`specs/epics/prototype_phase.md`)で実測 |
| Godot 4.7 移行時の破壊的変更 | 低〜中 | リリース後に nightly 互換性チェックジョブを設置 |
| GdUnit4 v6.x 非互換による将来の Godot アップ難 | 中 | 4.6 → 4.7 移行時に代替(GUT)も評価する選択肢を残す |
| LLM API のコスト想定超過 | 中 | 同時会話セッション制限、月次予算アラート(`ai_npc_dialog.md` §3.6) |
| GodotSteam のバージョン適合(Steamworks SDK 1.64 と Steam 側更新) | 低 | CI で互換性検証ジョブを定期実行 |

## フォロー

| # | 作業 | 担当 | トリガ |
|---|---|---|---|
| F-V01 | 本提案を **PO がレビューし、A 群を承認** | PO | 本ファイル作成後すみやか |
| F-V02 | 承認後、Claude Code が `docs/02_services/version_policy.md` §9 マトリクスに A 群を転記 + B 群の暫定値を入れる | Claude Code | F-V01 完了後 |
| F-V03 | C 群は使用工程到達時に個別決定ログを起票 | Claude Code | 各工程開始時 |
| F-V04 | Godot / Jolt の浮体物理検証をプロト工程で実施 | Claude Code | プロト工程開始時 |

## 関連

- 親決定: `pipeline/decisions/2026-05-05_gdd_initial.md`(F-02)
- 規約: `docs/02_services/version_policy.md`、`docs/02_services/service_catalog.md`、`CLAUDE.md §0` / §9
- 関連 spec: `specs/features/water_shader.md`、`specs/features/building_system.md`、`specs/features/multiplayer_session.md`、`specs/features/ai_npc_dialog.md`
- 採否決定軸はプロト epic で精緻化予定: `specs/epics/prototype_phase.md`(本承認後に起票)

## 出典

- [Godot Releases (GitHub)](https://github.com/godotengine/godot/releases)
- [Godot 4.6 Arrives With Major CG-Friendly Updates(Digital Production, 2026-01-28)](https://digitalproduction.com/2026/01/28/godot-4-6-arrives-with-major-cg-friendly-updates/)
- [Using Jolt Physics(Godot 公式)](https://docs.godotengine.org/en/latest/tutorials/physics/using_jolt_physics.html)
- [GodotSteam Updates blog(2026-03-27)](https://godotsteam.com/blog/2026/03/27/updates-updates-updates/)
- [GodotSteam GDExtension(Asset Store)](https://store.godotengine.org/asset/godotsteam/godotsteam-gdextension/)
- [GdUnit4 Releases(GitHub)](https://github.com/MikeSchulze/gdUnit4/releases)
- [Nakama Release Notes](https://heroiclabs.com/docs/nakama/getting-started/release-notes/)
- [Sentry Godot SDK(GitHub)](https://github.com/getsentry/sentry-godot)
- [Sentry for Godot Engine(公式 Doc)](https://docs.sentry.io/platforms/godot/)
- [butler(itchio GitHub)](https://github.com/itchio/butler)
