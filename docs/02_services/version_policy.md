# バージョン採択方針

## 1. 目的

本ドキュメントは、Godot エンジン・各種 SDK・外部 API モデル・Claude モデル等の **バージョン採択と固定の手順** を規定する。本テンプレートを再利用可能にするため、本ドキュメント群の他箇所にはバージョン番号を記載しない。

## 2. プロジェクト開始時の手順

1. 各カテゴリで「最新の安定版」または「最新でも実用上問題ないと判断できる版」を調査する
2. 採択結果を本ドキュメント末尾の **バージョンマトリクス** に記録する
3. 採択理由(調査日、根拠 URL、選定基準)も併記する
4. プロジェクトに固定する(`requirements.txt`, `package.json`, `project.godot`, CI 設定等)

## 3. 調査対象カテゴリ

- ゲームエンジン(Godot のメジャー/マイナー)
- 物理エンジン(Godot Physics / Jolt)
- スクリプト言語ランタイム(.NET の有無/バージョン)
- 各生成系 API のモデル(Tripo, Meshy, Stability, ElevenLabs, AIVA, DeepMotion, Audio2Face 等)
- LLM(Claude / OpenAI のモデル ID と最大トークン)
- MCP サーバ(Godot MCP Pro / GoPeak 等の release tag)
- テストフレームワーク(GdUnit4 / GUT)
- CI 用 Action(gdunit4-action / setup 系)
- 配布 CLI(butler / steamcmd / fastlane)
- バックエンド(Nakama サーバ / Edgegap)
- ローカライズ(Crowdin / DeepL の API 版)

## 4. 調査方法

- 各サービスの公式ドキュメント、リリースノート、GitHub Releases を確認
- Anthropic / OpenAI のモデルカードでコンテキスト窓・料金・廃止予定を確認
- セキュリティアドバイザリ(CVE 等)を確認
- 採用予定 OSS は最終コミット日とイシュー応答性で活発度を確認

## 5. バージョンの固定方法

| 対象 | 固定箇所 |
|---|---|
| Godot 本体 | CI 内の `setup-godot` バージョン引数、ローカル開発手順書 |
| .NET | `global.json` |
| Python | `.python-version` / `pyproject.toml` |
| Node | `.nvmrc` / `package.json#engines` |
| 依存ライブラリ | `requirements.txt` / `package-lock.json` 等のロックファイル |
| LLM モデル | `pipeline/scripts/config.yaml` の `model_id` |
| 外部 API モデル | 同上、サービスごとの `model` キー |
| MCP サーバ | `mcp.json` の参照タグ / コミット |

## 6. アップデート方針

- セキュリティ修正は迅速適用(影響範囲確認後)
- 機能追加・破壊的変更は **計画的に**(プロジェクト全体スプリント内で)
- 採択変更時は `00_overview/document_index.md` に改訂を記録

## 7. 互換性確認

破壊的変更の可能性がある場合、適用前に以下を実施:
1. ローカルで既存テストスイートを通す
2. CI で全プラットフォームビルドを通す
3. 視覚回帰の差分が許容範囲内か確認
4. 主要 API の動作を実呼出で確認

## 8. 危険信号

- 採用サービスのモデルが「near deprecation」と告知された
- サービスのライセンスが変更された
- レート制限・料金が大幅変更された
- 主要メンテナが離脱、または OSS リポジトリの更新が止まった

これらは `03_workflows/incident_response_workflow.md` を参照し、計画的な代替検討を開始する。

## 9. バージョンマトリクス(本作確定値)

> 採択根拠: `pipeline/decisions/2026-05-05_version_proposal.md`(調査) → `pipeline/decisions/2026-05-05_initialization_complete.md`(承認・ロック)
> 改訂は `08_process/decision_log_protocol.md` に従い意思決定ログを残し、本表を同 PR で更新する。
> 「未採用 (MVP)」: MVP では使わない。「未確定 (実装時)」: 該当工程開始時に個別決定ログで採択する。

### 9.1 コア基盤(A 群)

| カテゴリ | サービス/技術 | 採択バージョン | 採択日 | 根拠 URL | 備考 |
|---|---|---|---|---|---|
| エンジン | Godot | 4.6.2 | 2026-05-05 | https://github.com/godotengine/godot/releases | Jolt 既定化、最新安定 |
| 物理 | Jolt(Godot 同梱) | Godot 4.6.2 同梱 | 2026-05-05 | https://docs.godotengine.org/en/latest/tutorials/physics/using_jolt_physics.html | 別途インストール不要 |
| Steam 統合 | GodotSteam(GDExtension) | 4.18.1(Steamworks SDK 1.64) | 2026-05-05 | https://store.godotengine.org/asset/godotsteam/godotsteam-gdextension/ | Godot 4.6.x 対応確認済 |
| LLM | Claude モデル ID(主) | claude-opus-4-7 | 2026-05-05 | https://docs.anthropic.com/ | コード生成・オーケスト・主要 NPC |
| LLM | Claude Vision モデル | claude-opus-4-7(マルチモーダル) | 2026-05-05 | 同上 | スクショ視覚回帰判定 |
| LLM | Claude モデル ID(廉価系候補) | 未確定(実装時) | — | — | コスト計測後に Sonnet/Haiku 採否決定 |
| テスト | GdUnit4 | v6.1.3 | 2026-05-05 | https://github.com/godot-gdunit-labs/gdUnit4/releases | gdUnit4-action 公式互換性マトリクスで Godot 4.6.x は v6.1.x が必要(v5.0.x は 4.3〜4.4 専用、v6.0.x は 4.5 専用)。`pipeline/decisions/2026-05-05_gdunit4_version_correction.md` 参照 |
| 監視 | Sentry Godot SDK | 1.6.0 | 2026-05-05 | https://github.com/getsentry/sentry-godot | Win/Linux/macOS/Android/iOS 対応 |

### 9.2 周辺基盤(B 群)

| カテゴリ | サービス/技術 | 採択バージョン | 採択日 | 根拠 URL | 備考 |
|---|---|---|---|---|---|
| .NET | .NET SDK | 未採用 (MVP) | 2026-05-05 | — | GDScript 単一言語で運用 |
| Python | Python | 3.12.x(マイナーは ローカル `.python-version` で固定) | 2026-05-05 | https://www.python.org/downloads/ | パイプラインスクリプト用 |
| Node | Node.js | 20.x LTS | 2026-05-05 | https://nodejs.org/ | MCP / 配布 CLI 用 |
| CI | GitHub Actions Runner OS | ubuntu-latest / windows-latest / macos-latest | 2026-05-05 | https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners | 標準 Hosted Runner |
| CI | gdunit4-action | @v1(rolling) | 2026-05-05 | https://github.com/MikeSchulze/gdUnit4-action | GdUnit4 v6.1.3 を `version` 入力で指定 |
| 配布 | butler | rolling(broth から `LATEST` 取得、≥ 2026-01-28) | 2026-05-05 | https://github.com/itchio/butler | itch.io 公式推奨方式 |
| 配布 | steamcmd | rolling | 2026-05-05 | https://developer.valvesoftware.com/wiki/SteamCMD | Valve はバージョン管理しない |

### 9.3 後続採択(C 群、使用工程到達時に決定)

| カテゴリ | サービス/技術 | 採択バージョン | 採択日 | 根拠 URL | 備考 |
|---|---|---|---|---|---|
| 3D メッシュ | Tripo(サービス採用) | サービス採用確定 / モデル未確定(初回呼出時) | 2026-05-05 | https://www.tripo3d.ai/ | Pro プラン契約済。モデル(Draft/Refine 段階・version)は初回呼出時に固定し別途決定ログを起票。`pipeline/decisions/2026-05-05_island_assets_meshy_tripo_adoption.md` 参照 |
| 3D メッシュ | Meshy(サービス採用) | サービス採用確定 / モデル未確定(初回呼出時) | 2026-05-05 | https://www.meshy.ai/ | Pro プラン契約済。モデル(version)は初回呼出時に固定し別途決定ログを起票。同上 |
| テクスチャ | Stability モデル | 未確定(実装時) | — | — | 同上 |
| 高速画像 | fal.ai モデル | 未確定(実装時) | — | — | 同上 |
| HDRI | Blockade Skybox モデル | 未確定(実装時) | — | — | 同上 |
| mocap | DeepMotion モデル | 未確定(実装時) | — | — | アニメ要件確定後 |
| 顔アニメ | Audio2Face | 未確定(実装時) | — | — | リップシンク要件確定時 |
| BGM | AIVA モデル | 未確定(実装時) | — | — | 音響工程開始時 |
| BGM | Stable Audio モデル | 未確定(実装時) | — | — | 同上 |
| SFX | ElevenLabs SFX モデル | 未確定(実装時) | — | — | 同上 |
| TTS | ElevenLabs TTS モデル | 未確定(実装時) | — | — | 同上 |
| NPC | Inworld モデル | 未採用 (MVP) | 2026-05-05 | — | LLM NPC は Claude API で実装(`specs/features/ai_npc_dialog.md`) |
| MCP | Godot MCP Pro | 未確定(実装時) | — | — | 開発自動化強化段階で評価 |
| MCP | GoPeak | 未確定(実装時) | — | — | 同上 |
| バックエンド | Nakama サーバ | 未採用 (MVP) | 2026-05-05 | — | 専用サーバ採用はストレッチ |
| バックエンド | Edgegap | 未採用 (MVP) | 2026-05-05 | — | 同上 |
| 翻訳 | DeepL API | 未確定(実装時) | — | — | ローカライズ拡張時 |
| 翻訳管理 | Crowdin | 未確定(実装時) | — | — | 同上 |
| 分析 | GameAnalytics SDK | 未確定(実装時) | — | — | リリース前 |

### 9.4 採用しない(D 群)

| カテゴリ | サービス/技術 | 不採用理由 |
|---|---|---|
| 配布 | fastlane | モバイル展開が MVP 対象外 |
| 配布 | RevenueCat | F2P 課金経済を採用しないため(GDD §8.3) |
| アセット形式 | FBX 主要採用 | 第一推奨は GLB(`docs/04_standards/asset_standards.md` §3) |
