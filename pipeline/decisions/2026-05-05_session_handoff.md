# 2026-05-05 セッション引継メモ

> `docs/05_claude_code/session_protocol.md` §6・§7 準拠。本セッションの成果物・現状・次の一歩を集約。

## 今回の成果

### コミット
- `163c126 chore(init): scaffold Sunken Atoll per template docs`(142 ファイル)
- リポジトリは **ローカル init のみ**(リモート未設定 → push 未実施)

### 完了したタスク
1. プロト 3 種スキャフォールド(water / floating / multiplayer)
2. CI 最低限ジョブ(`.github/workflows/ci.yml`)整備
3. GDD 派生 spec 4 本(combat / faction / boat_navigation / day_night_cycle)
4. F-05 商標調査の発動 + アート安全範囲定義
5. `.tscn` 予防修正(broken PackedScene sub_resource 除去、`floating_block.tscn` 新規作成)
6. Git 初期化 + LFS 有効化 + Conventional Commits 規約準拠の初回コミット

## マージ可能か

**No(まだリモート未配置)**。次の人間操作で初めて push 可能になる。

## 次の人間操作(必須)

| # | 作業 | 必要性 | 詳細 |
|---|---|---|---|
| H-01 | **Godot 4.6.2 をローカルインストール** | プロト検証必須 | `pipeline/escalations/2026-05-05_godot_install_required.md` 参照 |
| H-02 | **GdUnit4 v5.0.4 addon 配置** | テスト実行必須 | 同上 |
| H-03 | **GitHub リポジトリ作成 + リモート設定 + 初回 push** | CI 動作確認に必須 | 例: `git remote add origin <URL> && git push -u origin main` |
| H-04 | **Godot 起動 → `--headless --import` 実行** | warnings 確認 | `import.log` を Claude Code に共有 |
| H-05 | **F-05 商標調査の実施** | アート工程 BLOCKED 解除 | `pipeline/escalations/2026-05-05_trademark_search_request.md` 参照 |
| H-06 | **`LICENSE` の `[Copyright Holder TBD]` 差替** | 外部配布前必須 | 法的実体名へ |

H-01〜H-05 は並行可能(H-04 は H-01・H-02 の後)。

## 次の一歩(Claude Code 側)

人間操作が一部でも進んだら、Claude Code がそれぞれ次を実施:

| トリガ | アクション |
|---|---|
| H-04 完了(import.log 共有) | warnings の原因特定 + 修正提案 |
| プロトベンチ実行結果共有 | `pipeline/decisions/2026-MM-DD_<proto>_result.md` 起票 |
| 3 プロトすべて合格判定 | `specs/epics/mvp_implementation.md` 起票(MVP 全体分解) |
| H-05 結果共有 | アート工程 BLOCKED 解除 → キービジュアル制作 Epic 起票 |
| H-03 完了(リモート push) | CI 初回実行確認、失敗ジョブの調整 |

## 残タスク(Claude Code 側のセッション内タスク)

| ID | 件名 | 状態 |
|---|---|---|
| 25 | Godot 4.6.2 インストールと headless import 検証 | **Pending — Open(PO 対応待ち)** |
| 26 | プロト実測と意思決定ログ起票 | **Pending — H-01 + H-02 + H-04 後** |
| 28 | F-05 待機状態の追跡記録 | 完了予定(本ファイルで充当) |

## 知っておくべき注意点

### 既知のリスク・前提
- 水面シェーダは **SSR / 屈折を含まない簡易版**(プロト目的では十分、本実装で SSR を追加)
- マルチプレイは **ENet ローカル動作のみ確認可能**(GodotSteam 統合は GDExtension 配置後)
- `LICENSE` 著作権者は **placeholder**(`[Copyright Holder TBD]`)
- バージョン採択 A 群はロック済だが、プロト実測で問題があれば改訂可能(本決定を Superseded by として扱う)

### Claude Code の独断回避事項
- タイトル変更を伴うリネーム作業 — F-05 結果次第
- AI 生成プロンプトに既存固有名(SUNKENLAND 等)を含める判断 — 厳守事項
- Godot バイナリの自動ダウンロード — サンドボックス制約により不可、PO 対応必須
- `git push` — リモート設定が PO の管理範囲

## 永続化したもの(再確認用)

| 場所 | 内容 |
|---|---|
| `docs/00_overview/project_charter.md` | 本作向けスコープ・成功基準 |
| `docs/02_services/version_policy.md` §9 | A 群バージョンロック済 |
| `docs/04_standards/quality_gates.md` §9 | 閾値マトリクス充足済 |
| `LICENSE` | Proprietary、placeholder 著作権者 |
| `specs/game_design_document.md` | GDD 初版(タイトル「Sunken Atoll」確定) |
| `specs/features/*.md`(9 本) | MVP 機能仕様 |
| `specs/epics/prototype_phase.md` | プロト工程計画 |
| `specs/epics/concept_art_safe_zone.md` | アート工程の安全範囲(F-05 と並行) |
| `pipeline/decisions/2026-05-05_*.md`(4 本) | 主要意思決定ログ |
| `pipeline/escalations/2026-05-05_*.md`(3 本) | エスカレーション記録 |
| `scenes/prototypes/{water,floating,multiplayer}/` | プロト実装 |
| `.github/workflows/ci.yml` | CI 最低限 |

## 参照

- 親決定: `pipeline/decisions/2026-05-05_initialization_complete.md`
- 関連エスカレーション: `pipeline/escalations/2026-05-05_godot_install_required.md`、`pipeline/escalations/2026-05-05_trademark_search_request.md`、`pipeline/escalations/2026-05-05_ip_similarity_check.md`
- セッションプロトコル: `docs/05_claude_code/session_protocol.md`

## 起票

- 起票日: 2026-05-05
- 起票者: Claude Code(Opus 4.7、本セッション主担当)
