# 用語集

本ドキュメント群および本プロジェクト内で使用する用語の定義を統一する。曖昧な語は必ず本用語集を参照すること。

## 一般

- **本プロジェクト**: 本ドキュメント群が規定する Godot 4 × Claude Code 駆動 3D ゲーム開発環境の総称。
- **テンプレート**: 本ドキュメント群そのもの。プロジェクト開始時にコピーして利用する。
- **プロジェクト開始時**: 本テンプレートを新規プロジェクトに適用する瞬間。バージョン採択、シークレット発行、API キー登録などをこの時点で実施する。

## 役割

- **プロダクトオーナー(PO)**: プロジェクトの最終意思決定者。仕様の承認、ストア配布の承認、商用利用判断を行う。
- **クリエイティブディレクター(CD)**: ゲームのビジョン、芸術的方向性の責任者。生成物の最終美的判断を行う。
- **オペレータ**: Claude Code を駆動する人間。プロンプトを与え、提案を承認/拒否する。
- **Claude Code**: 主オーケストレータとして動作する AI エージェント。本ドキュメント群を遵守する。
- **エージェント**: Claude Code が `Agent` ツールで起動するサブタスクの実行主体。

## エンジン関連

- **Godot 4**: 本プロジェクトの基盤ゲームエンジン。具体的なマイナーバージョンは `02_services/version_policy.md` で固定する。
- **シーン(Scene)**: Godot におけるノードツリーの一単位。`.tscn` ファイル。
- **ノード(Node)**: シーンの構成要素。継承可能。
- **リソース(Resource)**: 再利用可能なデータ単位。`.tres` ファイル。
- **GDScript**: Godot 標準スクリプト言語。
- **C#(.NET)**: Godot 公式の代替スクリプト言語。プロジェクト方針で採用可否を決める。
- **GDExtension**: ネイティブ拡張機構(C++/Rust 等)。

## アセット形式

- **GLB / glTF 2.0**: 本プロジェクトで第一推奨の 3D アセット形式。
- **FBX**: Godot 4 の `ufbx` インポータが処理する。リグ・アニメーション含む既存資産で利用する。
- **PBR(Physically Based Rendering)**: アルベド/メタリック/ラフネス/法線/AO の物理ベースマテリアル。
- **ORM**: Occlusion / Roughness / Metallic を 1 枚の RGB チャンネルにパックしたテクスチャ規約。

## パイプライン用語

- **オーケストレータ**: 工程全体を統制する主体。本プロジェクトでは Claude Code がこれを担う。
- **生成系サービス**: 3D メッシュ・音響・テクスチャなどを API 経由で生成する外部サービス。
- **MCP(Model Context Protocol)**: Claude が外部ツールと接続するためのプロトコル。
- **MCP サーバ**: MCP に従ってツールを公開するサーバ実装。
- **ヘッドレス**: GUI を起動せずに CLI で動作するモード。
- **再インポート**: Godot がプロジェクト内のアセットを再解析・再生成すること。
- **品質ゲート**: 工程を進めるために通過必須の自動チェック。
- **L0〜L5**: 自動化レベル。`05_claude_code/collaboration_guide.md` で定義する。

## 開発プロセス

- **仕様(spec)**: 自然言語または構造化テキストで記述された要求。`specs/` 配下に配置する。
- **タスク**: Claude Code の TaskCreate/TaskList で管理する作業単位。
- **プロンプト**: Claude Code に与える指示文。テンプレートは `05_claude_code/prompt_templates.md` を参照。
- **コンテキストウィンドウ**: LLM が一度に扱えるトークン数の上限。
- **エスカレーション**: Claude Code が判断保留し人間に判断を仰ぐ行為。

## 品質・テスト

- **シーンランナー(Scene Runner)**: テストフレームワーク(GdUnit4 等)が提供するシーン駆動実行環境。
- **視覚回帰(Visual Regression)**: スクリーンショット差分による UI/レンダリング検証。
- **シナリオテスト**: 入力 → 状態遷移 → 期待結果のシーケンスを検証するテスト。
- **アサーション**: テスト内の検証文。
- **オラクル**: テスト合否を判定する根拠。LLM オラクルは Vision を含む。
- **ハング検出**: タイムアウトと状態スナップショットによる進行不能検出。

## ガバナンス

- **CC0**: パブリックドメイン相当ライセンス。商用利用・改変・再配布自由。
- **ロイヤリティフリー(RF)**: 利用都度の支払不要(購入時条件に従う)。
- **商用ライセンス**: 商用利用が認められる契約形態。
- **帰属(Attribution)**: 作者表示義務。CC-BY 系で必要。

## 略語

| 略語 | 正式 |
|---|---|
| AAA | 大規模商用ゲーム |
| API | Application Programming Interface |
| CD | Creative Director / Continuous Delivery |
| CI | Continuous Integration |
| CLI | Command Line Interface |
| DAP | Debug Adapter Protocol |
| DCC | Digital Content Creation |
| DSL | Domain Specific Language |
| HDRI | High Dynamic Range Image |
| LFS | Large File Storage |
| LLM | Large Language Model |
| LOD | Level of Detail |
| MCP | Model Context Protocol |
| OSS | Open Source Software |
| PBR | Physically Based Rendering |
| PCG | Procedural Content Generation |
| PR | Pull Request |
| QA | Quality Assurance |
| RT | Real Time |
| SDK | Software Development Kit |
| SFX | Sound Effects |
| SOT | Single Source of Truth |
| TTS | Text to Speech |
| UV | UV mapping |
| VCS | Version Control System |
| WASM | WebAssembly |
| WS | WebSocket |
| XR | Extended Reality |
