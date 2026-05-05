# テストワークフロー

## 1. 目的

Godot プロジェクトおよび生成系成果物に対する **多層的な自動テスト** を Claude Code 駆動で運用する手順を規定する。

## 2. テスト分類

| 種類 | 目的 | 主な道具 |
|---|---|---|
| 静的検査 | 構文・型・規約 | Godot `--check-only`、リンタ |
| 単体テスト | 関数/クラス単位 | GdUnit4 / GUT |
| 統合テスト | シーン単位の相互作用 | GdUnit4 シーンランナー、GodotTestDriver |
| シナリオテスト | 進行可否(クエスト・遷移) | シーンランナー + 入力注入 + 状態アサーション |
| 視覚回帰 | レンダリング差分 | Godot MCP スクショ + Claude Vision + ベースライン |
| パフォーマンス | FPS / VRAM / draw call | `Performance.get_monitor()`、プロファイラ |
| ハング検出 | 進行不能・無限ループ | タイムアウト + 状態スナップショット差分 |
| クラッシュ・例外 | ランタイム例外 | stderr 捕捉、Sentry テスト環境 |
| マルチプレイ(任意) | 同期・整合性 | 複数クライアント並列起動 |

## 3. 配置

- `tests/unit/`: 単体
- `tests/integration/`: 統合
- `tests/scenarios/`: シナリオ
- `tests/visual/`: 視覚回帰(ベースライン: `tests/visual/baseline/`)
- `tests/perf/`: パフォーマンス

## 4. ローカル実行

```
godot --headless --import
godot --headless -s tests/run_all.gd
```

(具体コマンドはテストフレームワークの推奨に従う)

## 5. CI 実行

- `.github/workflows/ci.yml` で次の順序:
  1. インポート(警告を error として収集)
  2. 単体・統合・シナリオテスト
  3. 視覚回帰(変更ファイル影響範囲を優先)
  4. パフォーマンス(リグレッション閾値で fail)
- レポートは JUnit XML / HTML で artifact に保存

## 6. シナリオテストの設計

```
[Setup] テスト用シーン読込、決定論的な乱数シードと time_scale 設定
[Action] InputEventAction(または MCP)で入力注入
[Wait] 期待状態に到達するまで await
  - 到達: assert で確認 → pass
  - タイムアウト: 状態スナップショット dump → fail
[Teardown] シーン破棄、クリーンアップ
```

ハング検出は `await runner.simulate_frames(N)` の繰返中、N フレームごとに **位置・状態・スコアの変化** をログし、変化なしが続いた場合に fail とする。

## 7. 視覚回帰の運用

### 7.1 ベースライン作成
- 初回正常動作時のスクリーンショットを `tests/visual/baseline/<scene>/<step>.png` として保存
- 解像度・カメラ・ライティングを固定したテストシーン構成
- `--write-movie` で決定的フレーム出力

### 7.2 比較
- **数値比較**: SSIM / PSNR / ヒストグラム差分(高速・誤検出多)
- **意味比較**: Claude Vision で「視覚異常があるか」を判定(低速・少誤検出)
- 差分が閾値を超えるか Vision が異常を検知した場合 fail

### 7.3 差分の取扱
- 意図した変更なら **ベースライン更新 PR** を別途作成し、人間レビュー
- バグなら fix 後再実行

### 7.4 既知のノイズ要因
- アニメーション中の任意フレーム → 固定フレームを撮る
- 物理(乱数) → シード固定 + `Engine.time_scale = 0` などで停止
- パーティクル → テスト用シーンではパーティクル無効化フラグを使う
- ライトマップベイク → 事前にベイクし保存

## 8. Vision 解析プロンプト例

```
このスクリーンショットに以下の異常があるか確認せよ:
- ピンク/紫のマテリアル(欠損シェーダ・テクスチャ)
- 真っ黒/真っ白の領域(露出異常)
- 明らかなメッシュ崩壊
- UI 要素の画面外への突き抜け/重なり
- Z-fighting 由来の縞模様
- フリッカ・規則的な点滅
それぞれについて該当の有無、領域、信頼度を JSON で答えよ。
```

期待出力スキーマを別途固定し、Claude Code が機械的にパースして fail 判定する。

## 9. ハング検出の標準実装

```
スナップショット = []
for tick in range(timeout/dt):
    await simulate_frames(N)
    snap = capture_state(player, world, quest_manager)
    スナップショット.append(snap)
    if 到達条件(snap): return PASS
    if 直近 K 件のスナップショットが同一: return FAIL("HANG", snap)
return FAIL("TIMEOUT", スナップショット)
```

## 10. パフォーマンステスト

- 主要シーンで 30 秒間動かし FPS 平均 / 1% low、draw call、VRAM を測定
- ベースライン値からの劣化が一定以上なら fail
- 計測中は GC・並行ジョブを抑止

## 11. テストデータの非決定性対策

- 乱数: `RandomNumberGenerator` をシード固定で生成
- 時刻: モックの `Time` ラッパを通す
- ネットワーク: テスト用モックサーバ
- 物理: `--fixed-fps`、`Engine.physics_ticks_per_second`

## 12. テスト粒度の指針

- **単体**: 純粋関数 / Resource 計算 / 入出力ロジック
- **統合**: 単一シーン内の複数ノード相互作用
- **シナリオ**: ユーザストーリー単位(「クエスト A をクリアできる」)
- **視覚**: 主要 UI と代表的 3D シーン

## 13. レポート

- テスト結果: JUnit XML(CI 機械可読)+ HTML(人間用)
- 視覚レポート: スクリーンショット + Vision JSON + 差分 GIF/動画
- パフォーマンス: 指標時系列のグラフ
- 失敗時に **再現コマンド** を必ず添付

## 14. Claude Code の関与

- 失敗時の自動分析: スタックトレース + ログ + スクショを Vision に渡し、修正案を生成
- 自動修正は `04_standards/quality_gates.md` の許容範囲内に限定
- 自動修正不能と判定したらエスカレーション

## 15. 参照
- 規約: `04_standards/quality_gates.md`
- 障害: `03_workflows/incident_response_workflow.md`
- Claude Code 連携: `05_claude_code/collaboration_guide.md`
- 失敗対応: `05_claude_code/failure_playbook.md`
- レビュー: `08_process/review_procedure.md`
