# 2026-05-05 「Sunken Atoll」商標調査の依頼(F-05 発動)

## 種別

**人間判断要請**(`docs/05_claude_code/escalation_policy.md` §2.1「**法務・倫理** に関わる判断」該当)

## 文脈

正式タイトル「Sunken Atoll」が `pipeline/decisions/2026-05-05_initialization_complete.md` で確定した。同決定の F-05 として **主要 5 市場の商標調査** が PO 担当として登録されている。本ファイルはその発動とフォロー手続を定義する。

## Claude Code による予備調査結果

法務的な確定判断ではなく、**着手是非の参考情報** として実施。

### 調査方法
- WebSearch で「`Sunken Atoll` video game trademark brand」「`Sunken Atoll` game release Steam」を検索
- 結果は本決定ログ起票時点(2026-05-05)のもの

### 結果
- **「Sunken Atoll」完全一致のゲームブランドは Steam 上に未検出**
- 類似名称の既存ゲーム:
  - `Sunkenland`(本作の着想元、Vector3 Studio) — `appid 2080690`
  - `ATOLL`(Steam appid 1660240) — 一人称水中シミュレータ
  - `Sunken`(Steam appid 405960)
  - `Sinking Island`(Steam appid 333430)
  - `Sunken Engine`(Steam appid 3604780)

### 予備所見(法的判断ではない)
- **ポジティブ要因**: 「Sunken Atoll」完全一致のゲームタイトルは公開市場に未検出
- **要注意要因**:
  - 「ATOLL」単独タイトルが既存。商標として「ATOLL」がどの程度識別力ある語として登録されているか要確認(地理的・記述的語の場合は弱い保護、固有性が認められた場合は強い保護)
  - 「Sunken」も既存タイトル
  - 「Sunkenland」(着想元)との **音韻類似** がストア審査・商標審査でどう判定されるか不確実
- **推奨**: WebSearch 結果は **業界商習慣の指標であり、商標登録の可否判定には不十分**。USPTO TESS / EUIPO eSearch / J-PlatPat / 中国 / 韓国の **公式商標 DB を調査する必要** がある

## PO への依頼事項

### 必須(全体: ≤ 1 週間目安)

1. **公式商標 DB での「Sunken Atoll」検索**(下記出典の公式 DB)
   - US: USPTO TESS(Trademark Electronic Search System)
   - EU: EUIPO eSearch plus
   - JP: 特許情報プラットフォーム J-PlatPat
   - CN: CTM Online(中国商标网)
   - KR: KIPRIS

2. **Class 9 (electronic publications, computer software) と Class 41 (entertainment services) を中心に確認**
   - クラス 9: 電子ゲームソフト
   - クラス 41: ゲーム配信サービス

3. **音韻 / 視覚類似性の確認**
   - 「Sunken Atoll」と「Sunkenland」「ATOLL」「Sunken」等の既存登録との類似度
   - 主要市場の商標審査基準上、混同のおそれが認められるか

### 推奨(時間が許す場合)

4. **ドメイン取得可否確認**
   - `sunkenatoll.com`、`.io`、`.game` 等の主要 TLD
   - SNS ハンドル(Twitter/X、YouTube、Steam developer)

5. **Steam App 名としての利用可否予告確認**
   - Steamworks 内で名前申請は有料 ($100) で行われるため、申請前に competitor 名と区別されるかを確認

6. **法務助言の要否判断**
   - 上記 1〜2 で疑義が残る場合は **専門家(弁護士 / 知財コンサル)** の助言を求める
   - 助言費用の予算枠を `pipeline/decisions/` に別途記録

## 期限

| ステップ | 期限の目安 |
|---|---|
| 1〜2(公式 DB 調査) | 本依頼から 1 週間以内 |
| 3(類似性判断) | 同上 |
| 4〜5(ドメイン・Steam) | 2 週間以内 |
| 6(法務助言) | 必要時に発動 |

**ブロッキング条件**: アート工程の **タイトル / ロゴを含むビジュアル制作** はステップ 1〜3 完了まで保留。タイトル / ロゴに依存しない範囲は別途定義(`specs/epics/concept_art_safe_zone.md` 参照)。

## Claude Code の行動方針

- **タイトル変更を伴うリネーム作業を独断で実施しない**(変更指示があった場合のみ反映)
- アート関連のプロンプト・生成依頼で「Sunken Atoll」を含めるか PO 確認なしで判断しない
- 並行して進められる**安全範囲の作業**(`concept_art_safe_zone.md`)を提案

## 結果報告のフォーマット

PO は調査完了時、以下を本ファイルの追記または別ファイルとして残す:

```
## 調査結果(2026-MM-DD 報告)

### 公式 DB 検索結果
| 市場 | 検索クエリ | 一致 | 類似 | 評価 |
|---|---|---|---|---|
| US | "Sunken Atoll" / "SunkenAtoll" | 件数 | 件数 | OK / 要再検討 / NG |
| EU | 同上 | | | |
| JP | 同上 | | | |
| CN | 同上 | | | |
| KR | 同上 | | | |

### 結論
- [ ] 「Sunken Atoll」採用に法的障害なし → アート工程フル着手可
- [ ] 一部市場で要注意 → 該当市場の対応(命名変更 / ローカライズ別名 / 法務助言)を検討
- [ ] 採用不可 → 代替タイトルを GDD §9 Q-01 として再起票

### フォロー
- 必要なドメイン / SNS ハンドル取得
- Steam App 申請の予算化
- credits.md への商標表記反映(®/™)
```

## 関連

- 親決定: `pipeline/decisions/2026-05-05_initialization_complete.md`(F-05)
- 並行: `specs/epics/concept_art_safe_zone.md`(本依頼と並行で着手可能な安全範囲)
- 規約: `docs/07_governance/ip_policy.md` §6 / §7、`docs/07_governance/licensing.md` §8
- 既存エスカレーション: `pipeline/escalations/2026-05-05_ip_similarity_check.md`(本作全体の IP 類似性チェック方針、本依頼はその発動の 1 つ)

## 出典(予備調査)

- [Sunkenland on Steam](https://store.steampowered.com/app/2080690/Sunkenland/)
- [ATOLL on Steam](https://store.steampowered.com/app/1660240/ATOLL/)
- [Sunken on Steam](https://store.steampowered.com/app/405960/Sunken/)
- [USPTO TESS(参照)](https://tmsearch.uspto.gov/)
- [EUIPO eSearch plus(参照)](https://euipo.europa.eu/eSearch/)
- [J-PlatPat(参照)](https://www.j-platpat.inpit.go.jp/)

## ステータス

- 状態: **Open(PO 対応待ち)**
- 起票者: Claude Code
- 起票日: 2026-05-05
