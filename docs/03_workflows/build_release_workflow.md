# ビルド・リリースワークフロー

## 1. 目的

Godot プロジェクトをマルチプラットフォーム向けにビルドし、ストア/ホスティングへ配布するまでの自動化手順を規定する。

## 2. ビルド対象

プロジェクト開始時に決定する。代表例:
- Windows / macOS / Linux(デスクトップ)
- iOS / Android(モバイル)
- Web(HTML5 / WebAssembly)
- Quest 系(Android XR)
- コンソール(third-party publisher 経由、本テンプレートでは詳述せず)

## 3. ビルドフロー

```
[Trigger] tag 'v*' / main マージ / 手動
[1] チェックアウト + LFS フェッチ
[2] エクスポートテンプレートのインストール
[3] godot --headless --import
[4] 単体・統合・シナリオテスト(testing_workflow に従う)
[5] 視覚回帰
[6] godot --headless --export-release "<preset>" build/dist/<platform>/<artifact>
[7] チェックサム生成、署名(プラットフォーム別)
[8] アーティファクト保存(CI artifact + クラウド長期保管)
[9] 配布(release ジョブ)
```

## 4. エクスポートプリセット

`export_presets.cfg` に各プラットフォームのプリセットを定義する。プリセット ID は短く一意に。

- `Windows Desktop`
- `Linux/X11`
- `macOS`
- `Android`
- `iOS`
- `Web`

プリセット内の機密値(キーストアパスワード等)は **CI シークレットから注入** する。

## 5. 署名・公証

| プラットフォーム | 必須事項 |
|---|---|
| Windows | コード署名証明書(EV / OV) |
| macOS | Apple Developer ID 署名 + Notarization |
| iOS | プロビジョニングプロファイル + 署名 |
| Android | キーストア + Play 署名 |
| Web | TLS は配信側 |

`02_services/secrets_management.md` に従い、署名キーを安全に取り扱う。

## 6. 配布チャネル別手順

### 6.1 itch.io
```
butler push build/dist/windows/ user/game:windows-stable
butler push build/dist/macos/   user/game:macos-stable
butler push build/dist/linux/   user/game:linux-stable
butler push build/dist/web/     user/game:web
```

### 6.2 Steam
- Steamworks の `app_build.vdf` / `depot_build.vdf` をプロジェクトに同梱
- `steamcmd +login ... +run_app_build ... +quit`
- 既定では **default ブランチへ自動公開しない**(beta ブランチ → 動作確認 → 手動で default 昇格)

### 6.3 モバイル
- iOS: `fastlane match` で証明書、`fastlane gym` でビルド、`fastlane pilot` で TestFlight
- Android: `fastlane supply` で内部テスト → α → β → 本番

### 6.4 Web
- 静的ホスティング(Cloudflare Pages / Vercel / Netlify など)へ artifact デプロイ
- COOP/COEP ヘッダー設定必須(マルチスレッド対応)

## 7. リリースの段階

| 段階 | チャネル | 承認者 |
|---|---|---|
| 内部 nightly | CI artifact のみ | 自動 |
| dev preview | itch.io 限定リンク / Steam beta | Claude Code 自動 |
| プレリリース | TestFlight / Play 内部 / Steam beta | 人間承認 |
| 本番 | App Store / Play 本番 / Steam default | 人間承認 + ストア審査 |

## 8. リリースノート

- 自動生成: マージ済 PR の Conventional Commits から雛形作成
- 人間が要点を編集
- 配布物にも README として同梱
- ローカライズ要(`06_operations/localization.md` 参照)

## 9. ロールバック

- ストアごとのロールバック手順を `06_operations/distribution.md` に記載
- 本番に致命バグが出た場合: ストアバージョン停止 → ホットフィックス → 再申請
- データマイグレーションが絡む場合は復旧計画を別途 RFC 化

## 10. ビルドサイズ管理

- 配布前に **サイズレポート** を生成し閾値超過時に fail
- 主要圧縮: テクスチャ・音声・動画
- 不要シーン・テスト用アセットは export filter で除外

## 11. プラットフォーム最適化

- Web: gzip/brotli 配信、頭出しローダー
- モバイル: 64bit only、ABI split
- macOS: Universal Binary(Apple Silicon + Intel)
- Linux: AppImage / Flatpak も検討

## 12. 完了定義

- 全プラットフォームのテスト・ビルド・配布が CI で緑
- ストア側で受領済または公開済
- リリースノート、ハッシュ、ライセンス一覧が公開
- 監視ダッシュボードで初期トラフィックが正常

## 13. 参照
- CI 設定: `06_operations/ci_cd_pipeline.md`
- 配布詳細: `06_operations/distribution.md`
- 監視: `06_operations/monitoring.md`
- ブランチ・コミット: `08_process/branching_and_commits.md`
- 開発フロー: `08_process/development_flow.md`
