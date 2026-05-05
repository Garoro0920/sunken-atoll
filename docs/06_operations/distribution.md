# 配布・ストア運用

## 1. 目的

各配布先の **公開・更新・取下** の運用手順を定める。CI 連動の自動化と、人間承認が必要な工程の境界を明示する。

## 2. 配布先の決定

プロジェクト開始時にどのストア / プラットフォームに出すかを決定:
- itch.io、Steam、Epic、GOG(デスクトップ)
- App Store、Google Play(モバイル)
- Meta Horizon Store(Quest 等)
- 自前 Web ホスティング(WASM)

## 3. 配布先別概要

### 3.1 itch.io
- CLI: `butler`
- 自動配信に最適(個人〜インディー)
- チャンネル戦略: `windows-stable` / `macos-stable` / `linux-stable` / `web` / `<channel>-beta`

### 3.2 Steam
- Steamworks SDK + `steamcmd`
- ブランチ: `default` / `beta` / `internal`
- 配信フロー: ビルド → depot upload → 検証 → ブランチ昇格(人間承認)
- 実績(achievements)、クラウドセーブ、フレンド招待は別途設計

### 3.3 App Store
- Xcode Cloud or fastlane(`gym` + `pilot`)
- TestFlight → App Store 審査 → 公開
- スクリーンショット・キャプション・年齢分類・プライバシー詳細を提出

### 3.4 Google Play
- fastlane(`supply`)
- 内部 → α → β → 本番の段階配布
- App Bundle(.aab)、ABI split
- ターゲット API レベル更新義務

### 3.5 Meta Horizon Store(Quest)
- Quest CLI + Org アカウント
- リリースチャネル戦略
- 性能要件(VR は厳しい)を満たす

### 3.6 Web
- 静的ホスティング
- COOP/COEP ヘッダー
- 高速 CDN、頭出しローダー
- ブラウザ互換テストを別マトリックス

## 4. 公開前チェックリスト

- 全プラットフォームビルド成功(CI)
- 署名・公証完了
- ストア固有のメタデータ(タイトル、説明、画像、年齢、価格)入力済
- 多言語ローカライズ済(`localization.md`)
- 法務チェック(プライバシー文、利用規約)
- ストア固有要件(クラウドセーブ、実績、IAP テスト)

## 5. 公開直後の運用

- 監視ダッシュボードを集中観察
- リリース直後 24h は当番制
- 問題検知時は即時 `incident_response_workflow.md`

## 6. ロールバック

- itch.io: 旧チャンネルへ即時切替可
- Steam: 旧ブランチを default に戻すか、旧 build を default に固定
- モバイル: ストアの「リリース停止」+ 旧バージョン継続提供
- Web: 旧 artifact へ即時差替

## 7. 価格・地域

- 通貨・地域別価格はストア機能で設定
- セール戦略は別ドキュメント(任意)で管理
- 法令で規制される地域は配信を除外

## 8. 課金

- 配布物に決済ロジックを埋め込まない
- ストア決済 / RevenueCat 等の中継を使用
- レシート検証はサーバ側で実施(クライアントを信用しない)

## 9. ストア審査対応

- 拒否理由は記録、再申請時の修正点を spec 化
- 拒否率と平均審査時間を継続記録
- ストアポリシー変更は四半期レビュー

## 10. アンチパターン

- 全ストア同時に本番公開(問題発生時の対応負荷大)
- 自動公開設定を本番に向けて常時 ON
- ローカライズ未完了のまま公開
- リリースノート未整備
- 旧バージョン配布の一律停止(中途ユーザの被害)

## 11. 完了定義

- 公開済 / 非公開 / 更新済が明確
- 監視で安定稼働
- フィードバック窓口が稼働

## 12. 参照
- リリース: `03_workflows/build_release_workflow.md`
- 監視: `06_operations/monitoring.md`
- ローカライズ: `06_operations/localization.md`
- 法務: `07_governance/`
