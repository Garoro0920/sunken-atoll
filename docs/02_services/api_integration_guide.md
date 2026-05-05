# API 統合ガイド

## 1. 目的

本ドキュメントは、外部 API を本パイプラインに組み込む際の共通方針を規定する。サービス固有の事項は各サービスのドキュメント側で扱う。

## 2. 設計原則

1. **冪等性**: 同じ入力(プロンプト・パラメータ・シード)から同じ出力を再現できる
2. **観測可能性**: 全 API 呼出に一意の `request_id` を付与し、入出力を `pipeline/api_calls/` にログする
3. **タイムアウト明示**: 既定タイムアウトに依存しない。各 API ごとに合理値を設定する
4. **指数バックオフ**: 5xx と 429 は指数バックオフで N 回まで自動リトライ
5. **代替フェイルオーバー**: 重要 API は代替プロバイダへの切替経路を持つ
6. **dry-run 対応**: 開発中はモックレスポンスで動作可能であること
7. **レート/コスト制御**: 同時呼出と日次上限を設定し超過時はキューイング
8. **シークレット分離**: コード/コミット/ログには絶対に含めない

## 3. 共通インタフェース

### 3.1 呼出ラッパ仕様(言語非依存の概念)

```
client = ServiceClient(
    api_key=env("XYZ_API_KEY"),
    base_url=...,
    timeout=...,
    retries=...,
    dry_run=env_bool("DRY_RUN"),
    on_call=hook_log,
)
result = client.call(method, params, request_id=uuid4())
```

- `request_id` は呼出側で生成し、ログとレスポンスメタに紐づける
- `on_call` フックは呼出前後に呼ばれログに記録する

### 3.2 ジョブ系(非同期)

```
job_id = client.submit(...)
result = client.wait(job_id, timeout=..., poll_interval=...)
# または
result = client.callback(job_id)  # webhook 受信
```

### 3.3 ストリーム系(リアルタイム)

```
with client.connect() as ws:
    ws.send(...)
    for chunk in ws.stream():
        ...
```

## 4. リトライ方針

| 状態 | 対応 |
|---|---|
| 200 系 | 成功として扱う |
| 4xx(429 を除く) | 即時失敗。プロンプトやパラメータの問題として人間/Claude Code に通知 |
| 429 | バックオフ上限まで待機リトライ。超過時はフェイルオーバー |
| 5xx | 指数バックオフで N 回リトライ。全失敗時はフェイルオーバー |
| ネットワーク切断 | 短時間の再試行後、失敗扱い |

## 5. フェイルオーバー

- 「主」サービスへの呼出失敗時、`02_services/service_catalog.md` 記載の代替を順に試す
- フェイルオーバー時は `pipeline/decisions/` に切替理由を記録
- 代替先で生成された成果物は、次回以降の標準にしない(主が復旧したら主に戻す)

## 6. キャッシュ

- 同一プロンプト・同一パラメータ・同一シードでの結果は **キャッシュキー** で記録
- 開発・CI ではキャッシュヒットを優先(コスト削減と再現性向上)
- 強制再生成オプションを必ず提供する

## 7. dry-run / モック

- 環境変数 `DRY_RUN=true` で全 API がモックを返す
- モックは生成サービスごとに `pipeline/mocks/<service>/` に固定アセットを配置
- CI のスモークテストは dry-run で動作可能とする

## 8. ログ

`pipeline/api_calls/<YYYY-MM-DD>.jsonl` に 1 行 1 呼出で記録:

```json
{
  "request_id": "uuid",
  "ts": "ISO8601",
  "service": "tripo",
  "endpoint": "/v1/...",
  "params_redacted": { "...": "..." },
  "status": 200,
  "latency_ms": 4521,
  "cost_estimate_usd": 0.05,
  "result_ref": "pipeline/metadata/<id>.json"
}
```

API キー、PII、長大プロンプトの全文は `_redacted` でマスクする。長文は別ファイルに退避し参照する。

## 9. レート/コスト制御

- 各サービスごとに `max_concurrency` と `max_per_day` を設定する
- 超過予測時はキューイングし、Claude Code にも残量を通知する
- 高単価ジョブ(動画生成・大型 mocap)は **必ず人間承認** をエスカレーションフローで挟む

## 10. セキュリティ

- 認証情報は環境変数 / シークレットマネージャから取得(`02_services/secrets_management.md`)
- 受信ファイルはチェックサム検証(SHA-256)
- 受信ファイルはサンドボックスでスキャン(マルウェア・実行可能ファイルなど)
- 第三者 API は信頼境界を意識し、ローカルに展開する前に検証する

## 11. テスト

- 各サービスクライアントには **モック単体テスト** を必須とする
- 実 API テストは別ジョブで頻度を抑えて実行する
- テストでも本物の API キーを誤使用しないようガードする

## 12. ドキュメント

新サービスを追加する際は以下を行う:
1. `02_services/service_catalog.md` に行追加
2. `02_services/<service>.md` を新規作成(URL・モデル・制限・契約形態)
3. `02_services/version_policy.md` のバージョンマトリクスに追加
4. 必要なら `03_workflows/` の該当ワークフローを更新

## 13. 参照

- サービス一覧: `02_services/service_catalog.md`
- 認証情報: `02_services/secrets_management.md`
- バージョン採択: `02_services/version_policy.md`
- データフロー: `01_architecture/data_flow.md`
- アセット生成: `03_workflows/asset_generation_workflow.md`
- 障害対応: `03_workflows/incident_response_workflow.md`
