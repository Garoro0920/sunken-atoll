# 命名規約

## 1. 目的

すべての成果物の命名を統一し、検索性・読解性・自動化親和性を最大化する。

## 2. 全体原則

- 英語(ASCII)を基本、必要時は併記(コメントや表示文字列のみ)
- 意味を持つ単語を優先、略語は避ける(プロジェクト固有用語は用語集で許可)
- 動詞か名詞か役割が分かるように
- 複数語は **指定の区切り** に従う

## 3. 区切りパターン

| 区切り | 用途 |
|---|---|
| `snake_case` | ファイル名、ディレクトリ名、変数、関数、シグナル |
| `PascalCase` | クラス名、型名、Godot のノード名、シーン名 |
| `SCREAMING_SNAKE` | 定数 |
| `kebab-case` | URL パス、CLI フラグ |
| `dot.notation` | 設定キー |

## 4. ファイル / ディレクトリ

| 種類 | 例 |
|---|---|
| GDScript | `player_controller.gd` |
| C# | `PlayerController.cs` |
| シェーダ | `water_surface.gdshader` |
| シーン | `player.tscn`, `level_forest.tscn` |
| リソース | `enemy_data.tres`, `material_metal.tres` |
| アセット原典 | `assets/raw/meshes/dragon_<id>.glb` |
| アセット最適化 | `assets/optimized/meshes/dragon.glb` |
| プロンプト履歴 | `pipeline/prompts/<uuid>.json` |
| 仕様 | `specs/features/quest_<short>.md` |

## 5. 識別子

| カテゴリ | 規則 | 例 |
|---|---|---|
| 変数 | snake_case | `current_health` |
| プライベート変数 | 先頭 `_` | `_internal_state` |
| 関数 | snake_case 動詞句 | `take_damage()` |
| ブール返却関数 | `is_ / has_ / can_` | `is_grounded()` |
| 定数 | SCREAMING_SNAKE | `MAX_HEALTH` |
| 列挙型 | PascalCase + メンバ SCREAMING_SNAKE | `enum WeaponType { SWORD, BOW }` |
| クラス | PascalCase | `PlayerController` |
| シグナル | snake_case 過去/受動 | `health_changed`, `quest_completed` |
| ノード | PascalCase | `Camera3D`, `WeaponSlot` |
| グループ | snake_case | `enemies`, `pickups` |

## 6. シーン構造の命名

- ルート名はシーンの責務を表す PascalCase
- 子ノードは役割を反映: `Visual`, `Collision`, `Audio`, `AI`, `Hitbox`, `Hurtbox`
- 連番がある場合 `_01`, `_02` のようにゼロパディング 2 桁

## 7. アニメーション

- AnimationLibrary 内クリップ: snake_case 動詞句、状態遷移名
- 例: `idle`, `walk_loop`, `attack_combo_01`, `react_hit`, `die`
- 表情系: `face_<感情>`
- モーフ名は `face_<部位>_<方向>` 例 `face_brow_up`

## 8. 物理レイヤ・グループ

- 意味的命名: `world`, `player`, `enemy`, `pickup`, `trigger`, `npc_dialog`
- 数値は内部のみ、コードからは名前で参照(プロジェクト設定の Layer Names を活用)

## 9. ローカライズキー

- `<area>.<context>.<key>` 例 `ui.menu.start`, `dialog.npc_blacksmith.greeting_01`
- ピリオド区切りで階層
- 値は CSV / .po で多言語管理

## 10. アセット ID(生成系)

- UUID v4 を基本
- 表示・ファイル名と分離(可読化が必要なら別途 `slug` フィールドを持つ)
- 重複を絶対に避ける(API 経由で生成・記録)

## 11. ブランチ・コミット・PR

- ブランチ: `<type>/<short-desc>` 例 `feat/quest-spider-cave`
- type: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`, `build`, `ci`
- コミット: Conventional Commits、`type(scope): subject`
- PR タイトルもコミット規約に準ずる

## 12. テスト

- ファイル: `test_<対象>.gd`、`<対象>_test.gd` のいずれか(プロジェクトで一方を選ぶ)
- 関数: `test_<期待される振る舞い>` 例 `test_player_takes_damage_correctly()`

## 13. 環境変数

- `SCREAMING_SNAKE`、サービス接頭辞付き
- 詳細は `02_services/secrets_management.md`

## 14. CI ジョブ・ワークフロー

- ファイル: `kebab-case.yml`(`ci.yml`, `release.yml`, `visual-regression.yml`)
- ジョブ ID: snake_case
- ステップ名: 日本語/英語どちらでも可、簡潔に

## 15. 例外

- 既存 OSS の規約と衝突する場合は OSS の規約を優先
- 明示の理由を `# why:` コメントで残す

## 16. 違反検出

- リンタ + フォーマッタ + CI チェックで自動化
- レビューでも確認、矛盾があれば本ドキュメントを更新

## 17. 参照
- コーディング: `04_standards/coding_standards.md`
- 品質ゲート: `04_standards/quality_gates.md`
- ブランチ・コミット: `08_process/branching_and_commits.md`
