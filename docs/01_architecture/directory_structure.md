# プロジェクトディレクトリ構造

## 1. 目的

本ドキュメントは、Godot プロジェクト本体および関連ディレクトリの物理配置を規定する。Claude Code はこの構造を前提に動作する。

## 2. 推奨ルート構造

```
<project-root>/
├── CLAUDE.md                        # Claude Code 永続知識(プロジェクト固有)
├── README.md                        # プロジェクト概要(人間向け)
├── LICENSE                          # プロジェクト全体ライセンス
├── .gitignore                       # Git 無視
├── .gitattributes                   # Git LFS パターン定義
│
├── docs/                            # 本ドキュメント群(SOT)
│   ├── README.md
│   ├── 00_overview/
│   ├── 01_architecture/
│   ├── 02_services/
│   ├── 03_workflows/
│   ├── 04_standards/
│   ├── 05_claude_code/
│   ├── 06_operations/
│   └── 07_governance/
│
├── project.godot                    # Godot プロジェクト設定
├── icon.svg                         # アプリアイコン
├── default_env.tres                 # 既定環境
│
├── src/                             # ソースコード(GDScript / C#)
│   ├── core/                        # コア基盤(状態機械、イベント、ユーティリティ)
│   ├── gameplay/                    # ゲームプレイ実装
│   ├── ai/                          # AI(NPC, パスファインディング)
│   ├── ui/                          # UI 実装
│   ├── networking/                  # マルチプレイ(任意)
│   └── tools/                       # エディタ拡張
│
├── scenes/                          # シーン定義(.tscn)
│   ├── levels/                      # ステージ
│   ├── characters/                  # キャラクター単体
│   ├── ui/                          # UI シーン
│   └── prototypes/                  # 試作・実験用
│
├── resources/                       # 共有リソース(.tres)
│   ├── materials/
│   ├── shaders/                     # .gdshader / .gdshaderinc
│   ├── animations/                  # AnimationLibrary
│   ├── input_maps/
│   └── data/                        # ゲームデータ(JSON/CSV/.tres)
│
├── assets/                          # バイナリアセット(Git LFS 対象)
│   ├── raw/                         # 生成直後の原典
│   │   ├── meshes/
│   │   ├── textures/
│   │   ├── audio/
│   │   └── animations/
│   ├── optimized/                   # 最適化済(プロジェクトで実利用)
│   │   ├── meshes/
│   │   ├── textures/
│   │   ├── audio/
│   │   └── animations/
│   ├── third_party/                 # 既製素材(CC0 等)
│   └── fonts/
│
├── localization/                    # ローカライズリソース
│   ├── strings.csv                  # 翻訳キー
│   └── voices/                      # 多言語音声
│
├── tests/                           # 自動テスト
│   ├── unit/
│   ├── integration/
│   ├── scenarios/                   # シナリオテスト(進行可否)
│   └── visual/
│       ├── scenarios/               # 視覚回帰用シーン
│       └── baseline/                # ベースライン画像(Git LFS)
│
├── pipeline/                        # 生成パイプライン関連
│   ├── prompts/                     # プロンプト履歴(.json)
│   ├── metadata/                    # 生成物メタ(.json)
│   ├── history/                     # 実行履歴(.jsonl)
│   ├── decisions/                   # Claude Code 意思決定ログ(.md)
│   ├── api_calls/                   # API ログ
│   └── scripts/                     # オーケストレーション Python/Node
│
├── specs/                           # 仕様書(自然言語/構造化)
│   ├── features/
│   ├── levels/
│   └── epics/
│
├── export_presets.cfg               # Godot エクスポートプリセット
│
├── build/                           # CI 出力(Git 無視)
│   ├── dist/
│   ├── test_reports/
│   ├── screenshots/
│   └── logs/
│
├── tools/                           # 開発支援スクリプト
│   ├── orchestrator.py              # Claude Code が呼ぶオーケストレータ
│   ├── import_check.sh
│   └── visual_diff.py
│
└── .github/                         # CI 定義(GitHub Actions)
    └── workflows/
        ├── ci.yml
        ├── release.yml
        └── visual_regression.yml
```

## 3. 命名規則(本ドキュメントでの基本)

- ディレクトリ名は `snake_case`
- ファイル名は `snake_case.拡張子`
- シーン: `<名詞>.tscn`(動詞の単独命名は避ける)
- 詳細は `04_standards/naming_conventions.md` を参照

## 4. Git / Git LFS の取り扱い

`.gitattributes` で以下を LFS 対象とする(プロジェクト開始時に確定):
- `*.glb`, `*.fbx`, `*.obj`, `*.usd`, `*.usdz`
- `*.png`, `*.jpg`, `*.jpeg`, `*.exr`, `*.hdr`, `*.tga`, `*.psd`
- `*.ogg`, `*.wav`, `*.mp3`, `*.flac`
- `*.mp4`, `*.webm`
- `*.blend`

ベースライン画像も LFS で管理する。

## 5. `build/` と `pipeline/`

- `build/`: CI 生成物。`.gitignore` で除外。アーティファクトとして CI 側に保管
- `pipeline/`: 再現性のために Git に含める。ただしバイナリログは LFS 化を検討

## 6. 拡張性

- 新カテゴリのアセットは原則 `assets/<新カテゴリ>/` を新設
- スクリプトの新領域は `src/<新領域>/` を新設
- 必要に応じて `mods/`, `addons/`(GDExtension), `plugins/` を追加

## 7. アンチパターン

- ルート直下にバイナリを置く(必ず `assets/` 配下へ)
- 同一機能を `src/` と `tools/` に重複配置(`tools/` はビルド外)
- `scenes/` に巨大ファイルを 1 つだけ作る(分割可能なら分割する)
- `pipeline/scripts/` に秘密情報をハードコード(必ず環境変数経由)

## 8. 参照
- 命名規約の詳細: `04_standards/naming_conventions.md`
- 統合ワークフロー: `03_workflows/scene_assembly_workflow.md`
