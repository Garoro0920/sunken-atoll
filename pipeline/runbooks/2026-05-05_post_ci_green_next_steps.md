# CI Green 後の次ステップ runbook(N-01 〜 N-06)

> 起票日: 2026-05-05
> 対象: PO(`Garoro0920` アカウントで本リポジトリを操作)
> 前提: CI run `25353991104` 全ジョブ緑、コミット `52bbac9` まで `main` に反映済
> 目的: `pipeline/decisions/2026-05-05_session_handoff.md` の H-04/H-05/H-06 と、`pipeline/decisions/2026-05-05_gdunit4_version_correction.md` F-G02、CI 残警告 2 件 を体系的に消化し、プロト実測フェーズへ進む

---

## 全体像と依存関係

```
[N-01 F-G02] addon v6.1.3 差替 ─┐
                                 ├─→ [N-02 H-04 再実行] (ローカル import 検証)
[N-03 CI 低優先度修正] ──────────┘                  │
                                                     ├─→ プロト実測 (T26)
[N-04 H-05 商標調査] ── (PO 単独・並列実行可) ─────┘
                                                     │
[N-05 H-06 LICENSE 差替] ── (外部公開前必須・他と独立)
```

| ID | 作業 | 優先度 | 所要 | 依存 | 並列可 |
|---|---|---|---|---|---|
| N-01 | F-G02: addons/gdUnit4 を v6.1.3 に差替 | **高** | 10 分 | なし | N-04, N-05 と並列 |
| N-02 | H-04: `--headless --import` 再実行で warnings 0 確認 | **高** | 10〜30 分 | **N-01 推奨** | N-04, N-05 と並列 |
| N-03 | CI 低優先度修正(actions / setup-godot 引数) | 低 | 15〜30 分 | なし | 全タスクと並列 |
| N-04 | H-05: 商標調査(`pipeline/escalations/2026-05-05_trademark_search_request.md` 参照) | 中 | 1〜数日 | なし | 全タスクと並列 |
| N-05 | H-06: LICENSE 著作権者プレースホルダ差替 | 中 | 5 分 | (任意)N-04 結果反映 | 全タスクと並列 |

### 推奨実行順(時系列)

```
Day 0 (今日):
  09:00  N-04 開始 (公式 DB 検索を 5 市場で開始 → 数日かかる場合あり)
  09:30  N-01 開始 (10 分)
  09:40  N-02 実行 (import 確認)
  10:00  N-02 で warnings 出たら Claude Code に共有 → 修正反復
         warnings 0 達成後 → プロト実測 (T26) 着手可

Day 0〜1 (隙間時間):
  N-03 実施 (CI を触るタイミングで一括対応)
  N-05 PO 著作権者決定後 (即時 5 分作業)

Day N (N-04 完了時):
  N-04 結果が出たら BLOCKED 範囲解除 → アート工程着手
```

---

## N-01: ローカル `addons/gdUnit4` を v6.1.3 に差替(F-G02)

### 目的
ローカル開発環境のテスト実行が `tests/` 配下で正しく動作するよう、CI と同じ GdUnit4 v6.1.3 をローカル `addons/gdUnit4/` に配置する。
旧版(v5.0.4 等)が残っていると、エディタ起動時の互換性警告 / 一部 API 差異で混乱するため早期に揃える。

### 前提
- Godot 4.6.2 ローカル起動可能
- リポジトリは最新(`git pull`)

### 依存
なし(独立タスク)。先行する手動操作は不要。

### 手順

#### N-01-1. 旧 addon の状態確認

```sh
cd "/c/Users/FroGr/Desktop/3D Godot Projects/FirstProjects"
ls addons/ 2>/dev/null && cat addons/gdUnit4/plugin.cfg 2>/dev/null | grep version
```

期待される表示:
- `gdUnit4/` ディレクトリあり
- `plugin.cfg` に `version="..."`(現状おそらく `v5.0.4`)

`addons/` がそもそも存在しない場合 → §N-01-3 へスキップ(クリーンインストール)。

#### N-01-2. 旧 addon の安全な退避

```powershell
# PowerShell
$proj = "C:\Users\FroGr\Desktop\3D Godot Projects\FirstProjects"
$bk = "$env:USERPROFILE\Backup\gdUnit4_v5_$(Get-Date -Format yyyyMMdd_HHmmss)"
New-Item -ItemType Directory -Path $bk -Force | Out-Null
Move-Item "$proj\addons\gdUnit4" $bk -ErrorAction SilentlyContinue
Write-Host "Backup at: $bk"
```

> `addons/` は本リポジトリで `.gitignore` 済(`pipeline/decisions/2026-05-05_gdunit4_version_correction.md` 採用方針)のため、ローカル削除しても Git 状態に影響しない。

#### N-01-3. v6.1.3 ZIP のダウンロード

ブラウザで開く:

```
https://github.com/godot-gdunit-labs/gdUnit4/releases/tag/v6.1.3
```

「Assets」セクションから `gdUnit4-v6.1.3.zip` をダウンロード(50〜80 MB 程度)。

> v6.0.x は Godot 4.5 専用、v5.0.x は Godot 4.3〜4.4 専用なので、**必ず v6.1.x 系**(v6.1.3)を選ぶ。

#### N-01-4. 展開とプロジェクト配置

```powershell
$proj = "C:\Users\FroGr\Desktop\3D Godot Projects\FirstProjects"
$tmp = "$env:TEMP\gdunit4_v6_extract"
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive -Path "$env:USERPROFILE\Downloads\gdUnit4-v6.1.3.zip" -DestinationPath $tmp -Force

# zip 内構造を確認
Get-ChildItem $tmp -Recurse -Depth 2 -Directory | Select-Object FullName -First 10
```

zip 内が `addons/gdUnit4/...` 構造であることを確認。

```powershell
# プロジェクトの addons/ に配置
New-Item -ItemType Directory -Path "$proj\addons" -Force | Out-Null
Copy-Item "$tmp\addons\gdUnit4" -Destination "$proj\addons\" -Recurse -Force

# 配置確認
Get-Content "$proj\addons\gdUnit4\plugin.cfg" | Select-String "version"
```

期待: `version="6.1.3"`

#### N-01-5. Godot エディタでの認識確認

1. Godot エディタで本プロジェクトを開く
2. メニュー: 「プロジェクト」→「プロジェクト設定」→「プラグイン」タブ
3. `GdUnit4` 行が表示され「**有効**」状態であること確認
4. 自動的に `project.godot` の `[editor_plugins]` セクションが下記を含むこと(既に含まれているはず):
   ```ini
   [editor_plugins]
   enabled=PackedStringArray("res://addons/gdUnit4/plugin.cfg")
   ```

#### N-01-6. ローカル簡易テスト実行(動作確認)

エディタを開いている状態で:
1. メニュー: 「プロジェクト」→「ツール」→「GdUnit4」→「Inspector」(または `Ctrl+Shift+T`)
2. ツリーから `tests/integration/networking/replication_basic_test.gd` を選択
3. 「Run」ボタン

期待: `test_host_starts_with_local_peer` と `test_join_without_server_fails_gracefully` の **2 PASS**

または CLI で:
```sh
cd "/c/Users/FroGr/Desktop/3D Godot Projects/FirstProjects"
godot --headless -s res://addons/gdUnit4/runtest.sh -a res://tests/integration/networking/
```

### 検証
- `addons/gdUnit4/plugin.cfg` に `version="6.1.3"`
- Godot エディタでプラグイン有効
- 上記簡易テストが緑

### トラブルシュート

| 症状 | 原因 | 対処 |
|---|---|---|
| zip 内が `addons/gdUnit4/` でなく直接 `gdUnit4/` | リリース構造変更 | `Copy-Item "$tmp\gdUnit4"` のように親パスを 1 階層省略 |
| プラグイン有効化時にコンパイルエラー | Godot 起動中に古い addon が残ったまま swap した | エディタを完全終了 → swap 後に再起動 |
| `Class "GdUnitTestSuite" hides a global script class` | 旧 addon の残骸 | `addons/gdUnit4_old` 等のフォルダがないか確認、あれば削除 |
| エディタが反応しない | プラグインの初回コンパイルに時間がかかる(数十秒) | しばらく待つ |

### 完了通知
Claude Code に短く:
- `addons/gdUnit4/plugin.cfg` の version 行
- 簡易テスト 2 PASS の確認

→ Claude Code は N-02 へ案内、もしくはプロト実測タスク(T26)起票に進む。

---

## N-02: `--headless --import` 再実行で warnings 0 確認(H-04)

### 目的
プロジェクト全体が Godot 4.6.2 + GdUnit4 v6.1.3 で **import 警告 0** を満たすことをローカルで確認(`docs/04_standards/quality_gates.md` §9.1)。CI と同じ判定をローカルで先行実施することで、push 前のフィードバックを得る。

### 前提
- Godot 4.6.2 が PATH 上または既知パスで実行可能
- N-01 完了(addon が v6.1.3)
- リポジトリは最新

### 依存
**N-01 推奨**(必須ではないが、addon バージョン不整合があると無関係な警告で混乱する)。

### 手順

#### N-02-1. キャッシュクリア(任意・確実な再現性のため)

```sh
cd "/c/Users/FroGr/Desktop/3D Godot Projects/FirstProjects"
rm -rf .godot/  # 既存キャッシュを削除して初回 import を強制
```

> `.godot/` は `.gitignore` 対象なので削除して問題ない。次回 import で再生成される。

#### N-02-2. 1 回目の import(キャッシュ生成)

```sh
godot --headless --import 2>&1 | tee import_first.log
```

初回はインポート対象が多いため数十秒〜数分かかる。**この実行のログは参考情報のみ**(初回特有のメッセージが混ざる)。

#### N-02-3. 2 回目の import(確定的 warnings 抽出)

```sh
godot --headless --import 2>&1 | tee import.log
```

`.godot/` が既に揃っているため数秒で完了する。**こちらが本物の判定対象**。

#### N-02-4. ログ確認(CI と同じ条件)

```sh
# CI の "Fail on import warnings" と同等の grep
grep -E "(WARNING|ERROR)" import.log \
    | grep -v 'Could not load resource at path ""' \
    | grep -v "Addon 'res://addons/"
```

**期待: 何も出力されない(0 件)** — これが warnings 0 達成。

何か出力された場合は、その行を Claude Code に共有 → 修正反復。

#### N-02-5. キャッシュ生成の確認

```sh
ls -la .godot/ | head -5
```

`.godot/imported/` 等のディレクトリが生成されていれば成功。

### 想定される残存警告(本セッションで未検証のもの)

| 警告例 | 推定原因 | 対応 |
|---|---|---|
| `Shader compile error: ...` | 水面シェーダの Godot 4.6.2 API 差異 | エラー行を共有 → Claude Code が `water_surface.gdshader` を修正 |
| `Class "NetworkManager" hides a global script class` | 別の global class と競合 | リネーム(本作内では未検出だが GdUnit4 の class 群との衝突可能性) |
| `Class "FloatingNode" / "StructuralIntegrity" / etc. hides ...` | 同上 | リネーム |
| `[Spawner] floating_node_scene is null` | scene 実行時警告(import では出ない) | 無視可、scene_test 実行時に該当のみ |
| `.tscn parser error` | 未検出の構文不整合 | 該当 `.tscn` を Read → 修正 |

### 検証
```sh
# warnings 0 を改めて確認
grep -cE "(WARNING|ERROR)" import.log
# 期待: 0(または上記フィルタ後 0)
```

### トラブルシュート

| 症状 | 対処 |
|---|---|
| `godot: command not found` | Godot 4.6.2 の PATH 設定確認(H-01 §A-3〜A-4) |
| 大量の warnings | 1 件ずつ Claude Code に共有(全文 import.log でも可) |
| `.godot/imported` が空 | `--import` の前に `--editor --quit` で強制初期化(GUI 一瞬起動) |
| 初回で停止 | グラフィックドライバ依存の場合あり → `--rendering-driver opengl3` 追加 |

### 完了通知
- warnings 0 → Claude Code に「import.log clean」と一言
- warnings あり → `import.log` または上記 grep の出力を共有

→ Claude Code は修正提案 or プロト実測(T26、`specs/epics/prototype_phase.md` の各プロト個別実行)に進む。

---

## N-03: CI 低優先度修正(actions update + setup-godot 引数)

### 目的
CI run `25353991104` で出ていた **非ブロッキング警告 2 件** を解消し、長期メンテ性を確保:
1. Node.js 20 actions の deprecation(2026-09-16 まで猶予)
2. `chickensoft-games/setup-godot` の `install-templates` 引数が `include-templates` に rename された

CI は現在グリーンなので緊急ではないが、9 月以降に放置すると CI が動かなくなる可能性。

### 前提
- CI green 状態(現状達成済)
- `main` 直 push 可能(または PR 経由)

### 依存
なし(独立)。N-01〜N-05 のいずれとも並列可。

### 手順

#### N-03-1. 現在の actions バージョン棚卸

```sh
cd "/c/Users/FroGr/Desktop/3D Godot Projects/FirstProjects"
grep -nE "uses: " .github/workflows/ci.yml
```

現在使用中(コミット `52bbac9` 時点):

| Action | 現在版 | Node 警告 |
|---|---|---|
| `actions/checkout` | `v4` | あり(Node 20) |
| `actions/setup-python` | `v5` | あり |
| `chickensoft-games/setup-godot` | `v2` | (内部実装) |
| `MikeSchulze/gdUnit4-action` | `v1` | (内部実装) |
| `actions/upload-artifact` | `v4` | あり |
| `DavidAnson/markdownlint-cli2-action` | `v18` | あり |
| `gitleaks/gitleaks-action` | `v2` | あり |

#### N-03-2. 各 action の最新メジャー版確認

各リポジトリの Releases / Tags ページで Node.js 24 対応版を確認:

| Action | 確認 URL | 期待 |
|---|---|---|
| actions/checkout | https://github.com/actions/checkout/releases | v5 以降に Node 24 対応 |
| actions/setup-python | https://github.com/actions/setup-python/releases | v6 以降を想定 |
| actions/upload-artifact | https://github.com/actions/upload-artifact/releases | v5 以降を想定 |
| markdownlint-cli2-action | https://github.com/DavidAnson/markdownlint-cli2-action/releases | v19 以降 |
| gitleaks-action | https://github.com/gitleaks/gitleaks-action/releases | v3 以降 |
| chickensoft-games/setup-godot | https://github.com/chickensoft-games/setup-godot/releases | v3 以降 |

> 一度に全部上げると壊れることがあるため、**1 回 1 アクション**を推奨。CI が緑のまま小刻みに更新する。

#### N-03-3. `setup-godot` 引数 rename 修正

ci.yml の `Smoke build (Linux)` ジョブにある `chickensoft-games/setup-godot@v2` 呼出で:

```yaml
        with:
          version: ${{ env.GODOT_VERSION }}
          use-dotnet: false
          install-templates: true   # ← 旧名(警告対象)
```

を:

```yaml
        with:
          version: ${{ env.GODOT_VERSION }}
          use-dotnet: false
          include-templates: true   # ← 新名
```

に変更。

#### N-03-4. 1 アクションずつ更新する手順(雛形)

各 action ごとに同じ手順:

```sh
# 例: actions/checkout を v4 → v5 へ
cd "/c/Users/FroGr/Desktop/3D Godot Projects/FirstProjects"
sed -i 's|actions/checkout@v4|actions/checkout@v5|g' .github/workflows/ci.yml

# 変更を確認
git diff .github/workflows/ci.yml

# コミット (1 アクション 1 コミット)
git add .github/workflows/ci.yml
git commit -m "ci: bump actions/checkout to v5 (Node.js 24 compatibility)"

# push
git push

# CI 緑確認
gh run watch -R Garoro0920/sunken-atoll --exit-status
```

これを各 action 分繰り返す。

> もし更新後に CI が失敗した場合、その action の breaking change を確認:
> リリースノート(GitHub Releases ページ)を読み、必要な引数調整を行う。
> 失敗が続く場合は **元のバージョンに revert** して別 commit で再挑戦。

#### N-03-5. まとめてコミットする場合(短縮版)

慣れてきたら一括も可:

```sh
sed -i \
    -e 's|actions/checkout@v4|actions/checkout@v5|g' \
    -e 's|actions/setup-python@v5|actions/setup-python@v6|g' \
    -e 's|actions/upload-artifact@v4|actions/upload-artifact@v5|g' \
    -e 's|DavidAnson/markdownlint-cli2-action@v18|DavidAnson/markdownlint-cli2-action@v19|g' \
    -e 's|gitleaks/gitleaks-action@v2|gitleaks/gitleaks-action@v3|g' \
    -e 's|chickensoft-games/setup-godot@v2|chickensoft-games/setup-godot@v3|g' \
    -e 's|install-templates: true|include-templates: true|g' \
    .github/workflows/ci.yml

git diff .github/workflows/ci.yml  # 確認
git add .github/workflows/ci.yml
git commit -m "ci: bump GitHub Actions to Node.js 24 compatible versions"
git push
```

> ⚠ 上記の `@v5` 等は **2026-05 時点での例示** であり、実際の最新版は §N-03-2 で確認した値を使う。

### 検証

```sh
gh run list -R Garoro0920/sunken-atoll --limit 1
# 期待: latest run = success
```

GitHub Actions の警告セクションで Node.js 20 の deprecation 警告が **消えていること**。

### トラブルシュート

| 症状 | 対処 |
|---|---|
| ある action 更新後 CI 失敗 | リリースノート確認、引数の breaking change を反映、または前バージョンに戻す |
| `gdunit4-action@v1` を v2 に上げて失敗 | v1 系のメジャー API が安定しているため、必要時のみ更新 |
| Node 24 対応版がまだ無い action | `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true` を該当ジョブの env に追加して延命可(ただし暫定) |

### 完了通知
Claude Code に「CI green、Node.js 20 警告消失」と短く報告。

---

## N-04: H-05 商標調査の実施

### 目的
タイトル「Sunken Atoll」の主要 5 市場での法的安全性を確認し、`specs/epics/concept_art_safe_zone.md` の **BLOCKED 範囲を解除可能か判定** する。

### 前提
- 商標 DB へアクセス可(各国公式 DB は無料)
- 必要に応じ法務助言の連絡先を準備

### 依存
なし(独立、N-01〜N-03 と完全並列実行可能)。

### 手順

詳細手順は **`pipeline/runbooks/2026-05-05_po_unblock_h01_h06.md` §H-05** に既出のため、本ファイルでは差分のみ記述:

#### N-04-1. 5 公式 DB での検索(変更なし)

| 市場 | DB URL | 検索クエリ例 |
|---|---|---|
| US | https://tmsearch.uspto.gov/ | `Sunken Atoll` (Class 9 + 41) |
| EU | https://euipo.europa.eu/eSearch/ | 同上 |
| JP | https://www.j-platpat.inpit.go.jp/ | `Sunken Atoll` + `スンクン アトール` |
| CN | https://wcjs.sbj.cnipa.gov.cn/ | 同上 + `沉没环礁` |
| KR | http://eng.kipris.or.kr/ | `Sunken Atoll` |

#### N-04-2. 結果記録

新規ファイル `pipeline/decisions/2026-MM-DD_trademark_result.md` に旧ランブック §H-05 のテンプレートで記録。

#### N-04-3. 結論に応じた次アクション

| 結論 | 後続作業 |
|---|---|
| クリア | `specs/epics/concept_art_safe_zone.md` の BLOCKED 解除、新 Epic「キービジュアル制作」起票依頼 |
| 一部要注意 | 該当市場別名検討、法務助言取得 |
| 不可 | GDD §9 Q-01 再起票 → Claude Code に新タイトル候補 3〜5 案を依頼 |

### 完了通知
- 調査結果ファイルパス
- 結論カテゴリ(クリア / 要注意 / 不可)

→ Claude Code は適切な後続 Epic / spec 改訂を起票。

---

## N-05: H-06 LICENSE 著作権者プレースホルダ差替

### 目的
`LICENSE` ファイル内の `[Copyright Holder TBD]` を法的実体名に差替え、外部配布(プライベートアルファ含む)を可能な状態にする。

### 前提
- 著作権者の決定済(下記 §F-1 参照、`pipeline/runbooks/2026-05-05_po_unblock_h01_h06.md` §H-06 詳細)
- 神戸電子専門学校(または所属校)の **学生作品 IP 規定**を確認済(該当時)

### 依存
- 直接の依存はなし(N-01〜N-04 と並列可)
- ただし **N-04 で「タイトル変更」の結論が出た場合**は、新タイトル確定 → そちら反映完了後に LICENSE もまとめて更新する方が手戻り少ない

### 手順

詳細は **`pipeline/runbooks/2026-05-05_po_unblock_h01_h06.md` §H-06** 参照。要点のみ:

#### N-05-1. 著作権者表記の決定

| パターン | 表記例 |
|---|---|
| 個人開発 | `Garoro0920` (本名フルネーム推奨) |
| 個人 + 学校 | `Garoro0920 / 神戸電子専門学校` (学則準拠) |
| 任意団体 | `<団体名> Team` |
| 法人 | `<会社名>株式会社` |

学校所属の場合、学生作品の IP 帰属規定を **配布前に必ず確認**(担当教員 / 学校事務)。

#### N-05-2. ファイル編集

```sh
cd "/c/Users/FroGr/Desktop/3D Godot Projects/FirstProjects"
# 例: Garoro0920 個人を著作権者とする場合
sed -i 's|\[Copyright Holder TBD\]|Garoro0920|g' LICENSE

# PLACEHOLDER NOTICE ブロック削除
sed -i '/^=*$/,/^PLACEHOLDER NOTICE$/d' LICENSE  # 注: パターンが正確か git diff で確認
# 上記 sed が機能しない場合は手動でエディタで削除
```

#### N-05-3. 関連ドキュメント更新

`localization/credits.md`:
```markdown
## チーム
- Production: Garoro0920  (TBD だった行を更新)
```

(任意) `pipeline/decisions/2026-MM-DD_copyright_holder.md` に決定経緯を記録。

#### N-05-4. コミット & push

```sh
git add LICENSE localization/credits.md
git commit -m "$(cat <<'EOF'
chore(license): set copyright holder, remove placeholder notice

Refs: pipeline/decisions/2026-05-05_initialization_complete.md (F-04)
EOF
)"
git push
```

### 検証
```sh
grep "Copyright" LICENSE
grep "PLACEHOLDER NOTICE" LICENSE
# 期待: PLACEHOLDER NOTICE がヒットしないこと
```

### 完了通知
- 確定した著作権者表記
- コミット ID

→ 外部配布可能状態へ。

---

## 全体完了後の状態

N-01 〜 N-05 完了で達成される状態:

- ✅ ローカル開発環境がプロト実測 (T26) を即時開始可能
- ✅ CI が長期保守可能(Node.js 24 対応、警告ゼロ)
- ✅ 商標問題確定 → アート工程 BLOCKED の可否判明
- ✅ LICENSE が外部配布相当
- ✅ `CLAUDE.md` §9 末尾「これらが完了するまで、本格作業は開始しない」の **完全解除**

これにより以下の **本格実装フェーズ** へ移行可能:
1. プロト実測(`specs/epics/prototype_phase.md` の water / floating / multiplayer)
2. プロト合格判定 → MVP Epic 起票
3. キービジュアル制作 Epic(N-04 結果に応じて)
4. CI 拡張(視覚回帰本格運用、性能ベンチ常駐化)

## チェックリスト

```
[ ] N-01 addons/gdUnit4 を v6.1.3 に差替
    [ ] 旧 addon バックアップ
    [ ] zip ダウンロード
    [ ] 配置確認 (plugin.cfg version=6.1.3)
    [ ] エディタでプラグイン認識
    [ ] 簡易テスト 2 PASS

[ ] N-02 --headless --import warnings 0 達成
    [ ] .godot/ クリア
    [ ] import 2 回目で grep 0 件
    [ ] (失敗時) Claude Code に log 共有 → 反復

[ ] N-03 CI 低優先度修正
    [ ] actions 各社の最新版確認
    [ ] 1 アクションずつ更新 + push + 緑確認
    [ ] include-templates rename
    [ ] Node 20 警告消失確認

[ ] N-04 商標調査 (H-05)
    [ ] US / EU / JP / CN / KR 検索
    [ ] 結果記録 (pipeline/decisions/)
    [ ] 結論カテゴリ判定

[ ] N-05 LICENSE 差替 (H-06)
    [ ] 著作権者決定
    [ ] LICENSE 編集 + PLACEHOLDER NOTICE 除去
    [ ] credits.md 更新
    [ ] コミット + push

最終: 全 5 項目完了 → プロト実測 (T26) → MVP Epic 起票へ
```

## 関連

- 親 runbook: `pipeline/runbooks/2026-05-05_po_unblock_h01_h06.md`(H-01〜H-06 詳細)
- 親決定: `pipeline/decisions/2026-05-05_session_handoff.md`、`pipeline/decisions/2026-05-05_gdunit4_version_correction.md`
- 関連エスカレーション: `pipeline/escalations/2026-05-05_trademark_search_request.md`、`pipeline/escalations/2026-05-05_godot_install_required.md`
- バージョン根拠: `docs/02_services/version_policy.md` §9.1
- プロト計画: `specs/epics/prototype_phase.md`
- アート安全範囲: `specs/epics/concept_art_safe_zone.md`(N-04 結果で更新対象)

## 起票

- 起票日: 2026-05-05
- 起票者: Claude Code(本セッション主担当)
- 後続更新: 各 N タスク完了時点で本ファイル末尾にステータス追記、または `pipeline/decisions/` に個別決定ログを起票
