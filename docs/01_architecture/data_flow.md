# データフロー

## 1. 目的

本ドキュメントは、本パイプラインを流れるデータの種類・形式・経路・永続化方法を規定する。

## 2. データ分類

| 分類 | 例 | 永続化先 | バージョン管理 |
|---|---|---|---|
| 仕様 | spec.md, 機能要求 | `specs/` | Git |
| ソースコード | GDScript, C#, シェーダ | `src/` | Git |
| シーン定義 | `.tscn`, `.tres` | `scenes/` | Git |
| インポート設定 | `.import` | `*.import` 各所 | Git |
| プロジェクト設定 | `project.godot` | ルート | Git |
| 3D アセット(原典) | `.glb`, `.fbx` | `assets/raw/` | Git LFS |
| 3D アセット(最適化) | `.glb` | `assets/optimized/` | Git LFS |
| テクスチャ | `.png`, `.jpg`, `.exr`, `.hdr` | `assets/textures/` | Git LFS |
| 音響 | `.ogg`, `.wav`, `.mp3` | `assets/audio/` | Git LFS |
| 生成プロンプト履歴 | `.json`, `.yaml` | `pipeline/history/` | Git |
| 生成物メタデータ | `.json`(ライセンス・帰属・モデル名) | `pipeline/metadata/` | Git |
| テスト結果 | JUnit XML, HTML | `build/test_reports/` | 非永続(CI artifact) |
| スクリーンショット | `.png` | `build/screenshots/` | 非永続(CI artifact)、ベースラインのみ Git LFS |
| ビルド成果物 | プラットフォーム別バイナリ | `build/dist/` | 非永続(CI artifact) |
| シークレット | API キー | Secrets Manager / 環境変数 | **絶対に Git に入れない** |

## 3. 主要フロー

### 3.1 アセット生成フロー
```
spec.md
  └→ Claude Code: プロンプト構築
        └→ pipeline/prompts/<id>.json (記録)
              └→ 生成系 API
                    └→ assets/raw/<id>.glb (Git LFS)
                          └→ 加工(リトポ・圧縮等)
                                └→ assets/optimized/<id>.glb
                                      └→ pipeline/metadata/<id>.json
                                            └→ Godot 再インポート
                                                  └→ <path>.import
```

### 3.2 シーン構築フロー
```
仕様 + 既存資産
  └→ Claude Code: .tscn テキスト生成
        └→ scenes/<area>/<scene>.tscn
              └→ Godot 再インポート / シーン読込検証
                    └→ テストシーン(自動生成 or 既存)
                          └→ GdUnit4 ランナー
                                └→ JUnit XML
```

### 3.3 視覚検証フロー
```
ビルド済プロジェクト
  └→ Godot MCP: シーン起動 + 入力注入
        └→ 連続スクリーンショット
              └→ baseline と比較
                    └→ Claude Vision: 意味的判定
                          └→ 視覚レポート(JSON + Markdown)
```

### 3.4 配布フロー
```
CI ビルド成果物
  └→ プラットフォーム別 CLI(butler / steamcmd / fastlane)
        └→ ストア/ホスティング
              └→ 配布記録(リリースタグ / 変更履歴)
```

## 4. メタデータ仕様

すべての生成系出力に対し、以下を JSON で記録する:

```json
{
  "id": "uuid",
  "kind": "mesh|texture|audio|animation|...",
  "service": "tripo|meshy|elevenlabs|aiva|...",
  "model": "サービス側モデル名",
  "prompt": "完全なプロンプト",
  "seed": 12345,
  "parameters": { "polycount": 15000, "...": "..." },
  "generated_at": "ISO8601",
  "license": "CC0|RF|Commercial-Pro|...",
  "attribution": "必要なら表示文",
  "input_files": ["参考画像/動画のパス"],
  "output_files": ["assets/raw/xxx.glb"],
  "checksum": "sha256:..."
}
```

これにより **再現性、ライセンス追跡、トラブル時の原因特定** が可能となる。

## 5. ログ

- Claude Code の意思決定ログ: `pipeline/decisions/<date>.md`
- API 呼出ログ: `pipeline/api_calls/<date>.jsonl`
- ビルドログ: `build/logs/<run_id>.log`
- 個人情報・機密はログに残さない

## 6. リテンション

| データ | 保持期間 |
|---|---|
| ソース(Git) | 永続 |
| Git LFS バイナリ | プロジェクト寿命 |
| CI アーティファクト | 30〜90 日(設定可) |
| API 呼出ログ | 90 日 |
| 失敗時のスクショ・状態 dump | 30 日(調査後はサニタイズ) |

## 7. バックアップ

- Git リモートが第一バックアップ
- リリース成果物は別オブジェクトストレージへ二重化
- Secrets はシークレットマネージャ側のスナップショットに依存

## 8. 参照

- 全体像: `01_architecture/system_architecture.md`
- パイプライン: `01_architecture/pipeline_topology.md`
- ディレクトリ構造: `01_architecture/directory_structure.md`
- API 統合: `02_services/api_integration_guide.md`
- ライセンス記録: `07_governance/licensing.md`
