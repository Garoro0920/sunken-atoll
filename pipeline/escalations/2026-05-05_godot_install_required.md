# 2026-05-05 Godot 4.6.2 インストールが PO 側で必要(プロト検証ブロッカー)

## 種別

**人間操作要請**(`docs/05_claude_code/escalation_policy.md` §2.4 範囲外要求 / §3.4 自動修正の上限関連)

## 状況

セッション内で「Godot 4.6.2 インストール → `--headless --import` で warnings 0 確認 → プロト実測」を実行しようとしたが、Claude Code 実行サンドボックスが **外部実行可能ファイル(Godot 公式バイナリ)のダウンロードを安全機能としてブロック** した。

`Reason: Downloading Godot binary from GitHub releases is preparation for executing untrusted code from external sources outside the trusted repo's source control.`

これは Claude が任意の外部実行コードをユーザマシンに導入することを防ぐ妥当な制約であり、迂回すべきではない。

## 影響

以下のタスクが PO 側 Godot インストールまで **ブロック**:

| 影響タスク | 内容 |
|---|---|
| `--headless --import` 検証 | プロト 3 種(water / floating / multiplayer)が import warnings 0 を満たすか確認 |
| 水面ベンチマーク実行 | `tests/perf/water_benchmark.gd`(4 環境帯 × 600 フレーム計測) |
| 浮体ストームシナリオ | `tests/scenarios/building/storm_collapse_test.gd`(5 分検証) |
| マルチプレイ接続シナリオ | `tests/scenarios/multiplayer/connect_4players_test.gd` ほか |
| 各プロトの実測値による採否決定 | `pipeline/decisions/2026-MM-DD_<proto>_result.md` |
| MVP Epic 起票 | `specs/epics/mvp_implementation.md`(プロト合格を前提に分解) |
| GdUnit4 v5.0.4 addon の動作確認 | `addons/gdUnit4/` 配置後 |

## PO への依頼手順

### 1. Godot 4.6.2 のダウンロードとインストール

公式サイトまたは GitHub Releases から取得(いずれも公式署名済バイナリ):

```
公式: https://godotengine.org/download/windows/
GitHub: https://github.com/godotengine/godot/releases/tag/4.6.2-stable
```

ファイル: `Godot_v4.6.2-stable_win64.exe.zip`(.NET 不要)

展開先(任意): `C:\Tools\Godot\` または `%USERPROFILE%\Apps\Godot\`

PATH 追加(任意だが推奨):
```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Tools\Godot", "User")
```

### 2. GdUnit4 v5.0.4 addon の配置

```
URL: https://github.com/MikeSchulze/gdUnit4/releases/tag/v5.0.4
ファイル: gdUnit4-v5.0.4.zip
```

展開して `addons/gdUnit4/` をプロジェクトの `addons/gdUnit4/` に配置。

その後 `project.godot` の `[editor_plugins]` セクションを下記が含むよう調整(エディタで一度有効化すれば自動追加される):

```ini
[editor_plugins]
enabled=PackedStringArray("res://addons/gdUnit4/plugin.cfg")
```

### 3. 初回 import の実行

プロジェクトルート(`C:\Users\FroGr\Desktop\3D Godot Projects\FirstProjects`)で:

```sh
godot --headless --import 2>&1 | tee import.log
godot --headless --import 2>&1 | tee import.log  # 2 回目で確定的に warnings が出る
```

期待される結果(`docs/04_standards/quality_gates.md` §9.1):
- ERROR / WARNING の出力なし
- `.godot/` キャッシュディレクトリが生成される

### 4. 警告が出た場合の対応

警告を `import.log` ごと Claude Code に共有。Claude Code が原因を切り分けて修正提案を出す。よくある原因:
- `.tscn` の sub_resource ID の不整合(本セッションで予防修正済だが残存可能性あり)
- シェーダの `DEPTH_TEXTURE` / `INV_PROJECTION_MATRIX` 等の API 差異(Godot 4.6 で変更がある場合)
- `extends GdUnitTestSuite` 解決失敗(addon 未配置)
- `class_name` 競合(本作内で重複なし、Godot ビルトインとも競合なし — 確認済)

### 5. プロト個別起動(エディタで)

import 成功後、エディタを起動して各プロトシーンを F6 で実行:

| プロト | シーン | 確認 |
|---|---|---|
| 水面 | `scenes/prototypes/water/water_test.tscn` | 1〜4 キーで環境帯切替、`[`/`]` で嵐 |
| 浮体 | `scenes/prototypes/floating/floating_physics_test.tscn` | 100 個のブロックが浮く、Spawner.spawn_count を Inspector で 250/500 へ |
| マルチプレイ(2 インスタンス) | `scenes/prototypes/multiplayer/multiplayer_test.tscn` | 1 つで Host、もう 1 つで Join(127.0.0.1) |

### 6. ヘッドレス自動テスト実行

```sh
# 水面ベンチ(JSON レポート出力)
godot --headless -s res://tests/perf/water_benchmark.gd

# 浮体ストーム(5 分)
godot --headless -s res://tests/scenarios/building/storm_collapse_test.gd

# GdUnit4 経由のシナリオテスト
godot --headless -s res://addons/gdUnit4/runtest.gd -a res://tests/scenarios/multiplayer/
godot --headless -s res://addons/gdUnit4/runtest.gd -a res://tests/integration/networking/
```

### 7. 結果の Claude Code への共有

各実行結果を `pipeline/decisions/2026-MM-DD_<proto>_result.md` に記録(または raw 出力を Claude Code に共有して起票させる):

| プロト | 採否決定軸(`specs/epics/prototype_phase.md` §4.4 / §5.4 / §6.4) |
|---|---|
| 水面 | デスクトップ標準 1080p で 60 FPS、Steam Deck 720p で 40 FPS |
| 浮体 | 500 浮体・嵐 5 分・物理 tick ≤ 16.6 ms、倒壊なし |
| マルチプレイ | 4 接続 95% 成功、切断検知 ≤ 5 秒、再接続 95% |

## 代替案(検討したが不採用)

- **ユーザに `Bash permission rule` を追加してもらい、Claude が自動ダウンロード** — 「Claude が任意の URL から実行可能ファイルを取得できる」設定は本作 IP / セキュリティ方針上、過度なリスク
- **Web 版 Godot で代替** — Web エディタはまだ全機能未対応、ヘッドレスインポート不可
- **GodotSteam 等を含めスキップしテストだけ実行** — Godot 本体なしでは GDScript 構文検証もできない

## ステータス

- 状態: **Open(PO 対応待ち)**
- 依存: なし(独立作業)
- 期限: プロト工程 4 週間枠の最初の 1 週間以内に着手推奨(`prototype_phase.md` §7 スケジュール)
- 対応後の Claude Code 側アクション: import.log を確認し、警告の修正を提案 → プロト実測の起票

## 関連

- 親決定: `pipeline/decisions/2026-05-05_initialization_complete.md`(F-V02 / F-V04)
- プロト計画: `specs/epics/prototype_phase.md`
- バージョン採択: `docs/02_services/version_policy.md` §9.1
- CI(同じ Godot 4.6.2 を pinning): `.github/workflows/ci.yml`
- 起票者: Claude Code
- 起票日: 2026-05-05
