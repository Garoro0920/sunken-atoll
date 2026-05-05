# 認証情報(シークレット)管理

## 1. 目的

API キー・トークン・サービスアカウント鍵などの **機密情報の取扱を統一** し、漏洩を防ぐ。

## 2. 絶対遵守事項

1. シークレットを **コード・コミット・ログ・ドキュメント** に書かない
2. シークレットを Claude Code との対話に **貼付しない**(Claude Code が必要とする場合は環境変数経由で受け取る指示を与える)
3. 公開リポジトリで誤公開した場合、**即時失効・ローテーション** を行う
4. シークレットの所有者(発行アカウント)を必ず記録する

## 3. 保管場所

| 環境 | 保管先 |
|---|---|
| ローカル開発 | OS のシークレットストア(macOS Keychain / Windows Credential Manager / Linux secret-tool)+ `.env`(Git 無視) |
| CI/CD | GitHub Actions Encrypted Secrets / Environments |
| 本番ランタイム(マルチプレイサーバ等) | クラウドのシークレットマネージャ(例: AWS Secrets Manager 系) |
| チーム共有 | パスワードマネージャ(Bitwarden / 1Password 等) |

## 4. 命名規則

環境変数は大文字スネーク + サービス接頭辞:
- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY`
- `TRIPO_API_KEY`
- `MESHY_API_KEY`
- `STABILITY_API_KEY`
- `ELEVENLABS_API_KEY`
- `AIVA_API_KEY`
- `DEEPMOTION_API_KEY`
- `INWORLD_API_KEY`
- `BLOCKADE_API_KEY`
- `SKETCHFAB_API_TOKEN`
- `NAKAMA_SERVER_KEY`
- `SENTRY_AUTH_TOKEN`
- `STEAM_USERNAME` / `STEAM_PASSWORD` / `STEAM_GUARD_CODE`(配布のみ)
- `GITHUB_TOKEN`(自動)

サービスを追加した際は本ファイルにも追記する。

## 5. 配布物への混入防止

- ビルド前にバイナリへ直接埋め込まない
- ランタイム側の API キー(NPC 用 LLM 等)が必要な場合は **必ず自前バックエンド経由** にする(クライアントに鍵を持たせない)
- やむを得ずクライアントに置く場合(分析 SDK の公開キーなど)は本ドキュメントで明示し、Sentry のようなスコープ限定型のキーに限定する

## 6. ローカル `.env` の運用

- `.env` を Git 無視
- `.env.example` をコミットし、必要な変数名を列挙(値はダミー)
- `.envrc`(direnv)でディレクトリ移動時に自動ロード可能にする

## 7. CI のシークレット参照

- リポジトリ Secrets と Environment Secrets を使い分ける
- 重要操作(本番配布)は **Required reviewers** つき Environment を使い、人間承認を強制する
- ジョブログでは `add-mask::` で値を必ずマスクする

## 8. ローテーション

| シークレット | 推奨ローテーション |
|---|---|
| 主要 API キー | 90 日ごと |
| Steam パスワード | 180 日ごと |
| サービスアカウント鍵 | 365 日ごと、もしくは退職時 |
| 漏洩疑いのある全鍵 | 即時 |

## 9. 監査

- シークレットの利用イベントは可能な限りプロバイダ側の監査ログを有効化
- 漏洩スキャン(Gitleaks 等)を CI に組込む
- 公開予定のリポジトリに対しては **追加スキャン** を行ってから公開する

## 10. Claude Code との取扱

- Claude Code は環境変数を介してシークレットを受け取る前提で動く
- 対話で `ANTHROPIC_API_KEY` 等を貼付された場合、Claude Code はその値を扱わず **環境変数化を提案** する(`05_claude_code/dialogue_protocol.md` 参照)
- ログ出力前に値をマスクする責務を共有する

## 11. インシデント対応

漏洩発覚時の手順は `03_workflows/incident_response_workflow.md` の「シークレット漏洩」セクションに従う。

## 12. 参照

- API 統合: `02_services/api_integration_guide.md`
- サービス一覧: `02_services/service_catalog.md`
- 障害対応: `03_workflows/incident_response_workflow.md`
- メモリ運用: `05_claude_code/memory_policy.md`
- 対話プロトコル: `05_claude_code/dialogue_protocol.md`
- 配布(署名鍵): `06_operations/distribution.md`
