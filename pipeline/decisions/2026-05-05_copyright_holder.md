# 2026-05-05 著作権者の確定 — 個人名義(Garoro0920)

## 状態

- **Accepted**(承認・実施済)
- 親決定 `pipeline/decisions/2026-05-05_initialization_complete.md` D-03 のフォロー F-04 を **Resolves**

## 文脈

`pipeline/decisions/2026-05-05_initialization_complete.md` D-03 で本作のライセンスを **Proprietary / All Rights Reserved** とし、`LICENSE` を配置した。著作権者欄は `[Copyright Holder TBD]` プレースホルダで保留状態だった(F-04: 外部配布前に必須差替)。

PO より方針確定:
> 「著作権者の指定については "個人名義で登録する" 方針で確定しています」

これに基づき、`LICENSE` および `localization/credits.md` を更新する。

## 選択肢

- **A: 個人名義(GitHub ハンドル `Garoro0920` を使用)** ✓ 採用
  - 利点: PO が公開的に活動するアイデンティティ、リポジトリと一致、即時適用可
  - 欠点: 法的に厳密な「氏名」ではない。Steam 等の商用配布提出時には実名 / 法人名等の追加必要
- **B: 個人名義(法的氏名・本名フルネーム)**
  - 利点: 最も法的に堅牢、Steam 提出にも転用可
  - 欠点: 公開リポジトリに本名を晒すリスク(プライバシー)
- **C: 個人名義 + 学校共同**
  - 利点: 学校所属を反映
  - 欠点: 神戸電子専門学校の学生作品 IP 帰属規定を別途確認する必要があり、確認未了
- **D: 任意団体・チーム名**
  - 利点: 将来的なチーム化に拡張容易
  - 欠点: 現時点で個人開発のため過剰

## 決定

**A: `Garoro0920`(個人名義 / GitHub ハンドル)** を著作権者として採用。

`LICENSE` 内の `[Copyright Holder TBD]` を `Garoro0920 (individual / personal name)` に置換し、外部配布相当の状態とする。

### 反映箇所(本決定で更新済)

| ファイル | 変更 |
|---|---|
| `LICENSE` | 行 3: `Copyright (c) 2026 [Copyright Holder TBD]` → `Copyright (c) 2026 Garoro0920 (individual / personal name)` / PLACEHOLDER NOTICE ブロック削除 |
| `localization/credits.md` | `## チーム` セクション: `Production: TBD` → `Production: Garoro0920(個人名義)` + 本決定への参照 |

### 反映しなかった箇所

- 過去の意思決定ログ(`pipeline/decisions/2026-05-05_initialization_complete.md` 等)— `08_process/decision_log_protocol.md` §4 不変原則に従い原文保持

## 結果

期待される効果:
- `pipeline/decisions/2026-05-05_initialization_complete.md` フォロー **F-04 を解消**
- 本リポジトリが **外部配布相当の状態**(プライベートリポジトリでの配布、テスター招待、コミュニティ公開等)
- `CLAUDE.md` §9 初期化要件 + `D-03` フォローの全消化に近づく

## 引き換えのリスクと残存事項

| リスク | 対策 |
|---|---|
| Steam ストア提出時に実名 / 法人登録が必要 | Steamworks 申請段階で本決定を再起票(本決定を Superseded by として参照、新決定で実名 / 法人名を確定)。それまでは `Garoro0920` で運用 |
| 公開リポジトリでの著作権者表記が GitHub ハンドルのみ | 法的請求先が一意に特定しにくい可能性 → 事業化判断時に法的主体を明確化 |
| 学校所属(神戸電子専門学校)の学生作品 IP 規定未確認 | 学校事務 / 担当教員に **配布前必ず確認**(下記 F-CR-01) |
| GitHub ハンドル変更時の波及 | 改訂時は本決定を Supersede + 全関連ファイル更新 |

## フォロー

| # | 作業 | 担当 | トリガ |
|---|---|---|---|
| F-CR-01 | 神戸電子専門学校(または所属校)の **学生作品 IP 帰属規定** を担当教員 / 学校事務に確認 | PO | 外部配布(プライベートアルファ含む)実施前 |
| F-CR-02 | 規定が「学校所有」とされた場合、本決定を Supersede し著作権者を学校共同に再指定 | PO + Claude Code | F-CR-01 結果次第 |
| F-CR-03 | Steam Direct 申請段階で実名 / 法人登録に伴う著作権者再指定 | PO | Steamworks Direct 申請時 |
| F-CR-04 | 本作リリース 1 年経過時点で著作権表記の最新性確認(リスク台帳の四半期見直しに含む) | PO | リリース後 1 年 |

## 関連

- 親決定: `pipeline/decisions/2026-05-05_initialization_complete.md`(D-03 / F-04)
- 関連ファイル: `LICENSE`(更新済)、`localization/credits.md`(更新済)
- 規約: `docs/07_governance/licensing.md` §2 / §6、`docs/07_governance/ip_policy.md` §2 / §6
- 実行 runbook: `pipeline/runbooks/2026-05-05_post_ci_green_next_steps.md` §N-05、`pipeline/runbooks/2026-05-05_po_unblock_h01_h06.md` §H-06

## 起票

- 起票日: 2026-05-05
- 起票者: Claude Code(PO の方針指示「個人名義で登録する」に基づき具体的識別子として GitHub ハンドル `Garoro0920` を採用)
