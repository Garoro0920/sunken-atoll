# コーディング規約

## 1. 目的

GDScript / C# / シェーダ / シェルスクリプト / オーケストレーション(Python・Node)の **書式と書法** を統一し、Claude Code と人間の双方が読み書きしやすい状態を保つ。

## 2. 共通原則

1. **可読性を最優先**: 短い識別子よりも意図が伝わる名前を選ぶ
2. **型を明示**: 型システムが提供する保護を活かす
3. **副作用を局所化**: 純粋関数を優先、副作用は境界に集める
4. **早期 return**: ネスト浅く、ガード節で異常系を先に弾く
5. **コメントは Why のみ**: What はコードと識別子で語らせる
6. **死コードを残さない**: 使わないものは削除する
7. **マジックナンバー禁止**: 名前つき定数 or `.tres` データ駆動
8. **依存方向を統制**: コア層は外層を知らない、UI はコアに依存してよい

## 3. GDScript 規約

### 3.1 書式
- インデント: タブ
- 行末空白なし、末尾改行あり
- 1 行 100 文字を目安、超過は改行
- 1 ファイル 1 クラス、`class_name` を必ず付与
- ファイルは `snake_case.gd`、クラスは `PascalCase`

### 3.2 命名
- 変数・関数: `snake_case`
- 定数: `SCREAMING_SNAKE_CASE`
- シグナル: `snake_case`(過去/受動態)、例 `health_changed`, `quest_completed`
- ノードパス参照: `@onready var foo: TypeName = $NodePath`

### 3.3 型ヒント
- 引数・戻り値・変数すべてに型ヒント
- `Variant` の使用は理由を `# why:` で添える
- `null` ガードは早期 return

### 3.4 シグナルとコールバック
- シグナル定義は ファイル先頭付近
- 接続は静的に明示(エディタ接続より `connect` を推奨)
- 切断忘れに注意し、`tree_exiting` で必ず解除

### 3.5 デバッグ出力
- 製品ビルドでは `print` を残さない(ロガー経由)
- 段階別: `Logger.debug/info/warn/error/fatal`
- `assert` は `OS.is_debug_build()` ガードで重い計算を回避

### 3.6 例
```gdscript
class_name PlayerController
extends CharacterBody3D

const MOVE_SPEED: float = 5.0
const JUMP_VELOCITY: float = 6.5

signal health_changed(new_value: int)

@onready var _camera: Camera3D = $Camera3D

var _health: int = 100

func take_damage(amount: int) -> void:
    if amount <= 0:
        return
    _health = maxi(_health - amount, 0)
    health_changed.emit(_health)
```

## 4. C# 規約

- 採用時のみ。プロジェクト開始時にどこまで C# を使うかを決定する
- ファイル名はクラス名に一致(`PlayerController.cs`)
- `class_name` 相当として **namespace** を切る
- nullable 参照型を有効化、`?` を意味通りに使う
- `async` は CPU バウンド処理に使わない、I/O のみ
- 例外は本当の例外時のみ。フロー制御に使わない

## 5. シェーダ

- 拡張子: `.gdshader`、共有ロジックは `.gdshaderinc`
- ライティングモデルは Godot 標準 PBR を基準
- カスタムマテリアルは `04_standards/asset_standards.md` の PBR 規約に従う
- パフォーマンスを意識: 分岐削減、テクスチャ参照削減
- コメントは数式の意図を残す

## 6. シェルスクリプト / Bash

- `set -euo pipefail` を冒頭に
- 変数は `${VAR}` で展開、二重引用符必須
- 終了コードを意味的に使い分け、`exit` 直前にログ
- Windows でも動かす場合は **PowerShell 版を別途用意**

## 7. Python(オーケストレータ)

- バージョンは `02_services/version_policy.md` で固定
- 仮想環境を必須化
- フォーマッタ: ruff(format + lint)
- 型ヒント必須、`from __future__ import annotations`
- 例外時は構造化ログ(JSON)
- API クライアントは `02_services/api_integration_guide.md` の共通規約に準拠

## 8. Node(MCP / 配布スクリプト)

- TypeScript を優先
- `tsconfig` strict、`noUncheckedIndexedAccess` 有効
- ESM、明示的 import 拡張子
- フォーマッタ: prettier、リンタ: eslint
- 例外は型付き

## 9. ドキュメンテーション

- 公開 API には簡潔な docstring を付与
- 内部の自明な関数にコメントは書かない
- ドキュメントは Markdown(Github 互換)

## 10. テスト

- 1 テスト 1 検証
- AAA(Arrange-Act-Assert)
- 副作用のあるコードはテスト容易性のため依存注入
- フィクスチャは `tests/fixtures/`

## 11. リンタ・フォーマッタ

- GDScript: gdformat / gdlint
- C#: `dotnet format`
- Python: ruff
- TypeScript: prettier + eslint
- Markdown: markdownlint
- すべて pre-commit と CI で強制

## 12. 禁止・忌避事項

- グローバル可変状態(やむを得ない場合は明示的なシングルトン)
- 暗黙の型変換に依存
- 100 行を超える関数(分割を検討)
- ファイル末尾で複数機能を抱える
- 一時実験コードのコミット(WIP は別ブランチ)

## 13. レビュー

- すべての変更は PR 経由
- Claude Code が一次レビュー、人間が最終承認
- 大規模変更は段階的 PR 分割

## 14. 参照
- 命名: `04_standards/naming_conventions.md`
- 品質ゲート: `04_standards/quality_gates.md`
- シーン規約: `04_standards/scene_standards.md`
- レビュー: `08_process/review_procedure.md`
- ブランチ・コミット: `08_process/branching_and_commits.md`
- テスト: `03_workflows/testing_workflow.md`
