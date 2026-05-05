# ライセンス管理

## 1. 目的

本プロジェクトに含まれる **ソースコード・OSS 依存・生成物・既製アセット** のライセンスを把握・記録・遵守する。

## 2. 自プロジェクトのライセンス

- プロジェクト本体のライセンスを `LICENSE` に明記
- 採択候補(プロジェクト方針で確定): MIT / Apache-2.0 / GPL 系 / プロプライエタリ
- 採択時の注意:
  - GPL 系 OSS を依存に含む場合、自プロジェクトのライセンス選択肢が制約される
  - 商用配布の自由度を保ちたい場合は MIT / Apache-2.0 を優先

## 3. 依存ライブラリ

- 依存ライブラリの **SBOM(Software Bill of Materials)** をリリース毎に生成
- 各依存のライセンスを自動収集(`pip-licenses` / `npm license-checker` / `gdmaim` 等の生成ツール)
- 互換性チェッカ(GPL / LGPL / MIT / Apache-2.0)を CI に組込

## 4. 生成系アセットのライセンス

`pipeline/metadata/<id>.json` の `license` フィールドに以下のいずれかを記録:
- `CC0`(パブリックドメイン)
- `CC-BY`(帰属表示必要)
- `CC-BY-SA`(継承条件)
- `RF`(ロイヤリティフリー、購入時条件遵守)
- `Commercial-Service`(サービス契約に基づく商用許諾)
- `Service-RF`(サービスのプランで RF が保証)
- `Restricted`(限定用途のみ)

各サービスの商用条件は `02_services/<service>.md` 個別ドキュメントに明示する。

## 5. 既製アセット

- Poly Haven は CC0、利用にあたり帰属不要(任意で credits.md に記載)
- Sketchfab はモデルごとにライセンスが異なる、自動取得時にフィルタ必須
- Kenney は CC0 が中心
- 商用 RF アセット(購入素材)は購入記録を保管

## 6. 帰属表示(クレジット)

- `localization/credits.md` を Single Source of Truth とする
- ゲーム内の Credits シーンと配布物 README に同内容を反映
- 多言語化対応

## 7. AI モデルの学習データ

- 採用する生成系サービスの **学習データの出典** を必ず確認
- 出力物の権利が利用者に渡るかを確認(契約・利用規約)
- 不確実なサービスは商用採用を避ける

## 8. 商標

- 既存タイトル・人物・組織を想起させる名称を避ける
- ロゴ・色・字体は独自性を確認
- 商標登録の要否を地域別に検討

## 9. 音楽の権利

- AIVA Pro 等は完全著作権が利用者に帰属(契約確認)
- Suno / Udio など訴訟係争中のサービスは状況を継続的に確認
- 既存楽曲のカバー / サンプリングは個別の権利処理が必要

## 10. ロゴ・フォント

- フォントの埋込再配布権を確認
- 商用利用可能なライセンスのみ採用
- ライセンス文書をプロジェクトに同梱

## 11. ライセンス変更時の運用

- 採用サービスがライセンスを変更した場合
  - 既存生成物の遡及影響を確認
  - 必要なら差替え or 取下げ
  - メタデータと credits を更新

## 12. 監査

- リリース毎にライセンス監査を実施(CI で自動化)
- 不適合は blocker
- 監査結果を artifact に保存

## 13. インシデント

- ライセンス違反指摘 → `incident_response_workflow.md` の法務インシデント節
- 該当アセットを即時停止 → 差替え → 再リリース

## 14. テンプレート: アセットメタデータの license フィールド

```json
{
  "license": "Service-RF",
  "service": "elevenlabs",
  "service_plan": "<記入>",
  "terms_url": "<URL>",
  "verified_at": "ISO8601",
  "verified_by": "<オペレータ名>",
  "attribution_required": false,
  "attribution_text": null,
  "redistribution_allowed": true,
  "modification_allowed": true,
  "notes": ""
}
```

## 15. 参照
- メタデータ: `01_architecture/data_flow.md`
- サービス: `02_services/service_catalog.md`
- 知財: `07_governance/ip_policy.md`
- 倫理: `07_governance/ai_ethics.md`
- 意思決定記録: `08_process/decision_log_protocol.md`
