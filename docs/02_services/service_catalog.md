# サービスカタログ

## 1. 目的

本ドキュメントは、本パイプラインで採用する外部サービスを **役割別** に列挙し、各サービスの責務・代替候補・選定基準を規定する。具体的なバージョンや料金プランは記載しない(`02_services/version_policy.md` の手順で別途固定する)。

## 2. 採用基準(共通)

サービスは以下をすべて満たす場合に採用候補とする:
1. 公式 REST/gRPC/WebSocket API、または安定した CLI/SDK を提供する
2. 商用利用条件が API 経由で確定可能である
3. API キーの自己発行が可能である
4. プロジェクト開始時点でアクティブにメンテナンスされている

## 3. レイヤと採用候補

### L0. オーケストレーション・推論基盤

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| 主 LLM | Anthropic Claude API | OpenAI API |
| Embeddings | OpenAI Embeddings | Voyage AI |
| ベクトル DB | Pinecone | Weaviate Cloud / Qdrant Cloud |
| 汎用モデルホスト | Replicate | fal.ai / Hugging Face Inference |
| GPU コンピュート | Modal Labs | RunPod / Banana |

### L1. 3D メッシュ生成

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| メッシュ生成(リグ含) | Tripo AI | Meshy AI |
| 高精細メッシュ | Rodin AI | 3D AI Studio |
| パラメトリック | Sloyd.ai | — |
| 画像→シーン | CSM | Luma Genie |

### L2. テクスチャ・PBR

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| カスタム生成 | Stability AI(SD 系) | fal.ai(FLUX 系) |
| ゲーム特化 | Scenario | Polycam Texture |
| メッシュ貼付 | Tripo Texturing | Meshy Texture |

### L3. 環境・HDRI

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| HDR スカイ生成 | Blockade Labs Skybox AI | Stability(360°プロンプト) |
| 既製 HDRI | Poly Haven JSON API | — |

### L4. アニメーション・mocap

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| 動画 mocap | DeepMotion | Move.ai / Plask / RADiCAL |
| text→motion | DeepMotion SayMotion | — |
| Auto-Rig | Tripo Auto-Rig | — |

### L5. フェイシャル・リップシンク

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| 音声→顔アニメ | NVIDIA Audio2Face(NIM / OSS) | Rhubarb Lip Sync(軽量) |

### L6. 音響(BGM)

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| シネマ/MIDI | AIVA | Mubert |
| 楽曲 | Stability Stable Audio | Suno(第三者 API) |
| OSS セルフホスト | MusicGen / Stable Audio Open | — |

### L7. 音響(SFX)

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| 効果音 | ElevenLabs Sound Effects | Stable Audio |

### L8. 音響(ボイス・TTS)

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| ナレーション/NPC | ElevenLabs | OpenAI TTS |
| 感情表現 | Hume AI | — |
| リアルタイム会話 | Cartesia | OpenAI Realtime |
| ボイスクローン | ElevenLabs Voice Lab | Resemble AI |
| 多言語ダブ | ElevenLabs Dubbing | — |

### L9. 音響(アンビエント)

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| 環境音ループ | Stability Stable Audio | Mubert / Soundverse |

### L10. NPC AI(ランタイム)

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| NPC 性格管理 | Inworld AI | Convai |
| 物語ブランチ | Charisma.ai | — |
| 生 LLM 直接 | Claude API | OpenAI Realtime |

### L11. 既製アセット取得

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| CC0 既製 | Poly Haven API | — |
| 検索取得 | Sketchfab Data API | — |

### L12. 2D / コンセプト / UI

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| 高速画像 | fal.ai(FLUX 系) | Stability(SD 系) |
| 文字描画 | OpenAI GPT-Image | Ideogram |
| ベクター/UI | Recraft | — |
| ゲーム統一 | Scenario | — |

### L13. Godot 操作・実行(MCP)

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| エディタ・ランタイム制御 | Godot MCP Pro | GoPeak Godot-MCP |
| デバッガ統合 | GoPeak | — |
| エディタ + ゲーム Vision | GDAI | — |

### L14. テスト・QA

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| 単体・統合 | GdUnit4 | GUT |
| 統合ドライバ | GodotTestDriver | — |
| 視覚解析 | Anthropic Claude Vision | OpenAI Vision |
| クラッシュ | Sentry(公式 SDK) | BugSnag |

### L15. VCS / CI

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| VCS | GitHub | GitLab |
| CI | GitHub Actions | GitLab CI |
| LFS | Git LFS | — |
| MCP | GitHub MCP | — |

### L16. バックエンド・マルチプレイ

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| バックエンド | Nakama | Colyseus / PlayFab |
| ホスティング | Edgegap | Hathora |
| Steam 統合 | GodotSteam | — |

### L17. 運用・分析

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| クラッシュ | Sentry | — |
| 分析 | GameAnalytics | PostHog / Amplitude |
| サーバ運用 | DataDog | — |

### L18. 配布

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| インディー | itch.io(butler) | — |
| デスクトップ | Steam(steamcmd) | Epic / GOG |
| モバイル | fastlane(iOS/Android) | — |
| 課金統合 | RevenueCat | — |

### L19. ローカライズ

| 役割 | 採用候補(主) | 代替候補 |
|---|---|---|
| 翻訳管理 | Crowdin | Lokalise |
| 機械翻訳 | DeepL | Anthropic / OpenAI |
| 音声多言語 | ElevenLabs Dubbing | — |

## 4. 各サービス採用にあたっての必須記録

サービスごとに `02_services/<service>.md` を新設し以下を記録する:
- 公式 URL / API ドキュメント URL
- 採用バージョン / モデル名(プロジェクト開始時点)
- 認証方式(APIキー / OAuth)
- レート制限と料金プラン
- 商用ライセンスの確認文書 URL
- フォールバック先サービス
- 障害連絡先・SLA

## 5. 除外サービス

公式 API を持たない / 安定 CLI を持たない以下は本パイプラインから除外する。手動での試作には利用してよい:
- Mixamo(公式 API なし)
- Cascadeur(API なし)
- Midjourney(公式 API なし)

代替手段は本カタログ記載の他サービスで賄う。

## 6. 参照
- API 統合方針: `02_services/api_integration_guide.md`
- 認証情報管理: `02_services/secrets_management.md`
- バージョン採択: `02_services/version_policy.md`
