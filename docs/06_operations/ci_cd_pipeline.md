# CI/CD パイプライン

## 1. 目的

GitHub Actions(または同等の CI)上で、本プロジェクトの **インポート / テスト / 視覚回帰 / ビルド / 配布** を自動化する構成と運用を規定する。

## 2. 基本構成

`.github/workflows/` 配下に以下を配置:

| ファイル | トリガ | 役割 |
|---|---|---|
| `ci.yml` | PR / push | 静的検査、単体・統合・シナリオテスト、軽量視覚回帰 |
| `nightly.yml` | スケジュール | フル視覚回帰、フルテスト、依存ライセンス監査 |
| `release.yml` | tag `v*` | 全プラットフォームビルド + 配布(段階別) |
| `pages.yml`(任意) | docs 変更 | ドキュメントの静的配信 |
| `security.yml` | スケジュール + dependabot | シークレットスキャン、依存脆弱性、SBOM |

## 3. 共通方針

1. **再現性**: 依存ロックファイル、環境固定、キャッシュ
2. **観測性**: artifact 保存、ログ集約
3. **失敗の局所化**: 早期失敗、必要最小ジョブだけ再実行
4. **並列化**: マトリックスジョブで OS / プラットフォームを並走
5. **シークレット最小**: ジョブごとに必要最小だけ注入
6. **キャッシュ戦略**: 依存・エクスポートテンプレート・LFS をキャッシュ

## 4. ci.yml の標準ステップ

```
on: [pull_request, push: branches: [main]]
jobs:
  lint:
    - リンタ・フォーマッタ
    - シークレットスキャン
  import:
    - Godot ヘッドレス --import
    - 警告 0 を強制
  test:
    needs: [import]
    - 単体・統合・シナリオテスト
    - JUnit XML 保存
  visual_lite:
    needs: [import]
    - 主要 1〜数シーンのスクショ + Vision 軽量チェック
  build_smoke:
    needs: [import]
    - 1 プラットフォームのみのビルドスモーク
```

## 5. nightly.yml の標準

```
schedule: cron 毎日深夜
jobs:
  test_full:
  visual_full:
    - 全シナリオの視覚回帰
    - ベースライン差分レポート
  perf:
    - ベンチマークシーン実行
    - 指標時系列を artifact に保存
  license_audit:
    - 依存・アセットのライセンス再検査
```

## 6. release.yml の標準

```
on: push: tags: ['v*']
jobs:
  build_<platform>:
    matrix: [windows, macos, linux, android, ios, web]
  sign_<platform>:
    - 署名・ノータライズ
  package:
    - 圧縮、チェックサム、SBOM、リリースノート添付
  distribute_dev:
    - itch.io beta、Steam beta(自動)
  distribute_prod:
    - 本番配信(Environment Required Reviewers で人間承認)
```

## 7. キャッシュ

| 対象 | キャッシュキー |
|---|---|
| Godot エクスポートテンプレート | バージョン |
| LFS オブジェクト | git lfs ls-files のハッシュ |
| pip / npm 依存 | ロックファイルのハッシュ |
| 生成系 API モック / 既存 dry-run 応答 | プロンプトハッシュ |

## 8. アーティファクト

| 種類 | 保存先 | 保持 |
|---|---|---|
| テストレポート | CI artifact | 30 日 |
| スクショ・差分 | CI artifact | 30 日(失敗のみ 90 日) |
| ビルド成果物(dev) | CI artifact + クラウドストレージ | 30 日 |
| ビルド成果物(リリース) | CI artifact + 永続オブジェクトストレージ | 永続 |
| ベースライン更新 PR | 通常の Git | 永続 |

## 9. シークレット管理

- `02_services/secrets_management.md` を参照
- リポジトリ Secrets と Environment Secrets を使い分け
- 配布系は Required Reviewers で人間承認

## 10. プラットフォーム別注意

- **Windows**: 署名証明書、SmartScreen 対策
- **macOS**: Notarization と stapling、Apple Silicon 対応
- **iOS**: プロビジョニング・TestFlight・審査
- **Android**: keystore、64bit、Play 内部テスト
- **Web**: COOP/COEP、gzip/brotli、CDN
- **Quest**: APK 署名、組織アカウント

## 11. Godot ヘッドレス の利用

- インポート: `godot --headless --import`
- スクリプト実行: `godot --headless -s tools/<task>.gd`
- エクスポート: `godot --headless --export-release "<preset>" <out>`

## 12. SwiftShader / OSMesa

- GPU を持たないランナーで Vulkan / OpenGL を使う場合に検討
- ベースライン差分はソフトウェア描画と本物 GPU で結果が異なる可能性 → 同条件で運用

## 13. CI の Claude Code 統合

- Sentry MCP / GitHub MCP を介して PR コメントへ自動レポート
- 失敗の自動分析と再現スクリプト生成
- 自動修正の提案を別ブランチで作成、最終承認は人間

## 14. アンチパターン

- ジョブを 1 つに詰め込みすぎる(失敗の特定が困難)
- main ブランチに直接 push
- フルテストを毎 PR で走らせる(時間とコスト)
- シークレットを CI ログに出力
- 未使用の job をマトリックスに残し続ける

## 15. 参照
- 品質ゲート: `04_standards/quality_gates.md`
- リリース: `03_workflows/build_release_workflow.md`
- 監視: `06_operations/monitoring.md`
- ブランチ・コミット: `08_process/branching_and_commits.md`
- レビュー: `08_process/review_procedure.md`
