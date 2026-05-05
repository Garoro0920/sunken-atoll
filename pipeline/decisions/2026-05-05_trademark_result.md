# 2026-05-05 商標調査結果(F-05)— US/EU/JP クリア、CN/KR 未確認

## 状態

- **Accepted**(部分達成)
- 親エスカレーション `pipeline/escalations/2026-05-05_trademark_search_request.md` を **部分的に Resolves**
- CN/KR 部分は **新たな F-05B として後続化**(本決定 §フォロー参照)

## 文脈

タイトル「Sunken Atoll」採用にあたり、`pipeline/decisions/2026-05-05_initialization_complete.md` F-05 として 5 主要市場の公式商標 DB 検索を PO 担当で実施した(`pipeline/runbooks/2026-05-05_po_unblock_h01_h06.md` §H-05、`pipeline/runbooks/2026-05-05_post_ci_green_next_steps.md` §N-04)。

## 調査結果(2026-05-05 報告)

### 公式 DB 検索結果

| 市場 | DB | 検索クエリ | 結果 | 評価 |
|---|---|---|---|---|
| US | USPTO TESS | `Sunken Atoll` | 一致なし | **クリア** |
| EU | EUIPO eSearch plus | 同上 | 一致なし | **クリア** |
| JP | J-PlatPat | 同上 + カタカナ表記候補 | 一致なし | **クリア** |
| CN | CTM Online | — | DB へのアクセス不可で検索不能 | **未確認** |
| KR | KIPRIS | — | 公式サイト到達不可で検索不能 | **未確認** |

### 結論

- **US / EU / JP の 3 主要市場で同一商標未登録** を確認。これらの市場で「Sunken Atoll」採用に **法的障害は確認されず**
- CN / KR は技術的アクセス障害により未検証 — **アジア市場展開の判断時点で再調査必須**
- 本作の MVP 配信ターゲット(`docs/00_overview/project_charter.md`「本作の特定」: Steam デスクトップ)は US/EU/JP 中心のため、**現時点でのリスクは低い**

## 決定

「Sunken Atoll」を **正式タイトルとして継続採用**(`pipeline/decisions/2026-05-05_initialization_complete.md` D-02 を維持・追認)。

これに基づき:
1. `specs/epics/concept_art_safe_zone.md` の **§4 BLOCKED 範囲を解除**(タイトル / ロゴ / 主要キャラ / キービジュアル等の制作着手可)
2. `specs/epics/concept_art_safe_zone.md` の **§5 REVIEW 待ち項目** も解除可(PO 個別承認は引き続き必要)
3. CN / KR 市場展開判断時点で再調査(下記フォロー参照)

## 結果(期待される効果)

- アート工程の **キービジュアル制作 / ロゴ確定 / 主要キャラ意匠** に進行可能
- ストアページ・パッケージアート相当の本格制作可
- US / EU / JP での Steam リリースには **追加調査不要**(ただし主要意匠確定時に再確認推奨)

## 引き換えのリスクと残存事項

| 残存リスク | 対策 |
|---|---|
| CN / KR 未確認(アジア市場拡大時に未知の衝突可能性) | 拡大判断時点で **F-05B**(下記)を発動。それまで該当市場での公開・販売を行わない |
| 公式 DB 検索後の新規登録(他者が「Sunken Atoll」を申請する可能性) | 主要マイルストーン(コンセプトアート確定 / ストア提出前)で **再検索** を `pipeline/escalations/2026-05-05_ip_similarity_check.md` ESC-01〜04 に従い実施 |
| 自社商標未登録(防衛的登録なし) | 本作リリース後の事業判断で商標登録を検討(`docs/07_governance/ip_policy.md` §6) |

## フォロー

| # | 作業 | 担当 | トリガ |
|---|---|---|---|
| F-05A-01 | `specs/epics/concept_art_safe_zone.md` の §4 / §5 / §7 を更新(BLOCKED 解除を反映) | Claude Code | 本決定と同時に実施 |
| F-05A-02 | キービジュアル制作 Epic を新規起票(`specs/epics/key_visuals.md`) | Claude Code | アート工程開始指示時 |
| F-05B | CN / KR 市場展開検討時の **追加商標調査** | PO + 必要に応じ法務 | アジア市場展開判断時 |
| F-05C | 主要意匠(タイトルロゴ / 主要キャラ視覚)確定前に US/EU/JP 公式 DB **再検索**(同名新規申請の検出) | PO | コンセプトアート確定〜ストア提出前 |
| F-05D | リリース 1 年経過時点で全市場再調査(`docs/07_governance/ip_policy.md` §13 リスク台帳の四半期見直しに含む) | PO | リリース後 1 年 |

## 関連

- 親決定: `pipeline/decisions/2026-05-05_initialization_complete.md`(D-02 / F-05)
- 親エスカレーション: `pipeline/escalations/2026-05-05_trademark_search_request.md`(本決定で部分 Resolves)
- 関連エスカレーション: `pipeline/escalations/2026-05-05_ip_similarity_check.md`(継続)
- 規約: `docs/07_governance/ip_policy.md`、`docs/07_governance/licensing.md`
- 影響範囲: `specs/epics/concept_art_safe_zone.md`(更新対象)、GDD §10
- 実行 runbook: `pipeline/runbooks/2026-05-05_post_ci_green_next_steps.md` §N-04

## 起票

- 起票日: 2026-05-05
- 起票者: Claude Code(PO の調査結果報告に基づき記録)
- PO 報告: 主要 3 市場(US / EU / JP)で同一商標未登録、現時点リスク低と判断
