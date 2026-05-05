# Sunken Atoll

協力型マルチプレイ・サバイバル・クラフトゲーム(海洋・水没世界)。
Godot 4 を基盤とし、Claude Code を主オーケストレータとする 3D ゲーム開発パイプライン上で構築する。

正式タイトル確定: 2026-05-05(`pipeline/decisions/2026-05-05_initialization_complete.md`)

## ドキュメント

本プロジェクトの **唯一の正(SOT)** はリポジトリ内のドキュメントである。コードを書く前に必ず以下を参照すること。

- [プロジェクト憲章](docs/00_overview/project_charter.md)
- [ゲームデザインドキュメント(GDD)](specs/game_design_document.md)
- [ドキュメント索引](docs/00_overview/document_index.md)
- [ドキュメント README](docs/README.md)
- [Claude Code 永続知識](CLAUDE.md)

## クイックスタート(開発者向け)

1. リポジトリをクローン(Git LFS が必要: `git lfs install`)
2. `.env.example` を `.env` にコピーし、必要な API キーを設定
3. Godot 4 をインストール(バージョンは `docs/02_services/version_policy.md` 参照)
4. プロジェクトを開く: `godot --editor` または Godot エディタから本ディレクトリを開く
5. インポート完了を待ち、開発を開始

## ライセンス

本プロジェクトは **Proprietary / All Rights Reserved**(`LICENSE` 参照)。
著作権者名は placeholder で配置済み(外部配布前に法的実体名へ差替必要)。
第三者コンポーネント(OSS 依存・生成系アセット・既製素材)はそれぞれの原ライセンスに従う。詳細は `docs/07_governance/licensing.md` および `localization/credits.md` を参照。

## コントリビュート

- ブランチ・コミット規約: `docs/08_process/branching_and_commits.md`
- レビュー手順: `docs/08_process/review_procedure.md`
- 完了基準: `docs/08_process/definition_of_ready_done.md`
- AI 倫理ガイドライン: `docs/07_governance/ai_ethics.md`

## 参照元の明示

本作はジャンル方向性の参照点として SUNKENLAND(Vector3 Studio)を扱うが、
固有意匠・名称・ロゴ・キャラクタ・コード・テクスチャ等は一切流用しない独自作品である。
詳細は `specs/game_design_document.md` §10 を参照。
