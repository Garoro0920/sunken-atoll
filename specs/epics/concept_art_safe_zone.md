# Epic: コンセプトアート工程 — 商標調査と並行可能な安全着手範囲

| 項目 | 内容 |
|---|---|
| 状態 | **Updated 2026-05-05**: F-05 主要 3 市場クリア(`pipeline/decisions/2026-05-05_trademark_result.md`)→ §4 BLOCKED 解除済 |
| 親 GDD | `specs/game_design_document.md` §1.5(アートディレクション) |
| 起票日 | 2026-05-05 |
| 関連 | `pipeline/escalations/2026-05-05_trademark_search_request.md`(F-05、部分 Resolved)、`pipeline/escalations/2026-05-05_ip_similarity_check.md`(全体方針)、`pipeline/decisions/2026-05-05_trademark_result.md`(本 Epic 解除根拠) |

## 1. 目的

「Sunken Atoll」の商標調査(F-05)が完了するまでアート工程全体を停止せず、**タイトル / ロゴ / 主要キャラ意匠に依存しない範囲** で並行着手できる作業を定義する。

これにより F-05 完了後に **タイトル依存作業を即座に開始可能** な状態を維持する。

## 2. 設計原則

| 原則 | 根拠 |
|---|---|
| タイトル / ロゴを含めない | `pipeline/escalations/2026-05-05_trademark_search_request.md` ブロッキング条件 |
| キャラクタの**シルエット・意匠の最終決定**は保留 | `ip_policy.md` §6(主要意匠の商標調査必須) |
| 環境・世界観のムードは先行可 | ジャンル参照は許容(`game_design_document.md` §10.2) |
| AI 生成プロンプトに既存固有名(SUNKENLAND 等)を**絶対に含めない** | `ip_similarity_check.md` の厳守事項 |
| 生成物の license / metadata 記録は通常通り | `data_flow.md` §4 |

## 3. 安全範囲(SAFE)— 並行着手可能

### 3.1 環境ムード制作
- 4 環境帯(浅瀬 / 半水没都市 / 沿岸遺跡 / 深海帯)の **雰囲気スケッチ**(キーアートではない)
- カラースクリプト(時間帯 / 天候別の配色案)
- 光・霧・水中ボリュームの参考画像収集 / 自作習作

#### 担当: CD ディレクション、生成は Claude Code 補助
#### 出力先: `specs/levels/<area>_mood.md` + 参考画像(著作権 OK のもののみ)

### 3.2 環境構成要素のコンセプト
- 漂着物バリエーション(樽 / 木材 / 金属片 / 漁網)
- 浮体構造のスケッチ(プレイヤー拠点の発展段階)
- 自然要素(海面の波、海生生物のシルエット)

#### 出力先: `specs/features/world_props.md`(未起票、必要時起票)

### 3.3 UI ムード
- HUD のレイアウトラフ(タイトル文字を含めない)
- アイコン体系の **意匠方向性**(色・線の太さ・形状コンセプト)
- フォント候補(タイトル用ではなく**本文 / UI 用**フォント)

#### 出力先: `specs/features/ui_design.md`(未起票)

### 3.4 サウンド方向性(アート要素として)
- 環境音のリファレンス収集
- BGM ジャンル選定(GDD §9 Q-10 進行)

### 3.5 技術プロト用プレースホルダ素材
- `scenes/prototypes/` 配下で使用する **明らかにダミーと分かるプリミティブ**(灰色立方体・キャプセル等)
- アートディレクション確定前の検証目的

## 4. 旧 BLOCKED 範囲 — **2026-05-05 解除済**

> `pipeline/decisions/2026-05-05_trademark_result.md` に基づき本節は **解除**。
> 後続作業として `specs/epics/key_visuals.md`(キービジュアル制作 Epic)を別途起票する想定(F-05A-02)。
>
> ただし以下の継続条件あり:
> - 主要意匠(タイトルロゴ / 主要キャラ視覚)確定前に **US/EU/JP 公式 DB 再検索**(F-05C)
> - **CN / KR 市場展開判断時** に追加調査(F-05B)
> - AI 生成プロンプトに既存固有名(SUNKENLAND 等)を含めない厳守事項は継続
> - 自己チェック(`ip_similarity_check.md` チェック観点)は引き続き必須

### 4.1 タイトル / ロゴ ✓ 着手可
- 「Sunken Atoll」表記を含むロゴデザイン
- タイトルロゴアニメ
- 任意のテキストロゴワーク全般

### 4.2 主要キャラクタ ✓ 着手可
- プレイヤーキャラの顔・服装・体格の確定意匠
- 派閥代表 NPC のキービジュアル
- マスコット的存在のデザイン

### 4.3 重要意匠(看板級)✓ 着手可
- メインアートワーク(Steam ページ用)
- パッケージアート相当
- プロモーション素材

### 4.4 UI のタイトル要素 ✓ 着手可
- メインメニュー画面のタイトル表示
- スプラッシュ画面
- ローディング画面のタイトル

## 5. 中間範囲(REVIEW)— PO 個別承認で着手可

| 内容 | 判断ポイント |
|---|---|
| プレイヤーキャラのシルエット**ラフ**(意匠確定前) | F-05 結果次第で意匠を継承するか破棄するかが決まる前提なら可 |
| 派閥のシンボル意匠**コンセプト**(具体的なロゴ化前) | 同上 |
| 主要建築物のスタイル方向性 | ジャンル一般的範囲なら可、既存作品との類似は避ける |
| AI 生成によるムード画像 | プロンプトに既存固有名なし、出力に既存意匠類似なしを目視確認 |

## 6. 着手フロー

```
[1] 安全範囲の作業を選定
[2] CD と方向性合意(必要時、PO 承認)
[3] 制作 / 生成
[4] 生成物のメタデータと license を pipeline/metadata/ に記録
    (data_flow.md §4 仕様準拠)
[5] 既存意匠類似性の自己チェック(ip_similarity_check.md チェック観点)
[6] 中間範囲の作業は PO 個別承認 → 着手
[7] 保留範囲は F-05 完了まで待機
```

## 7. F-05 完了状態(2026-05-05 達成)

F-05 結果: **US / EU / JP の 3 主要市場でクリア**(`pipeline/decisions/2026-05-05_trademark_result.md`)。
これにより本 Epic は次の状態へ:

1. ✅ §4 旧 BLOCKED 範囲は **解除**(2026-05-05)
2. ⏳ §5 REVIEW 待ち項目も着手可(PO 個別承認は継続)
3. ⏳ 別 Epic「キービジュアル制作」(`specs/epics/key_visuals.md`)を起票(F-05A-02、アート工程開始指示時)
4. ⏳ CN / KR 市場展開時に F-05B 発動(本 Epic 範囲外)
5. ⏳ 主要意匠確定前に F-05C(US/EU/JP 再検索)発動

本 Epic は **キービジュアル制作 Epic 起票時点で archive 予定**(両 Epic 並走の混乱回避のため)。

## 8. 受入基準(Epic レベル DoD)

- [ ] 安全範囲の制作物が `specs/levels/<area>_mood.md` 等に蓄積
- [ ] 各制作物のメタデータが `pipeline/metadata/` に記録
- [ ] 自己チェック(ip_similarity_check.md チェック観点)を実施した記録がある
- [ ] F-05 完了時に保留範囲を即座に着手できる準備が整っている

## 9. アンチパターン(本 Epic で避けるべき行為)

- AI 生成プロンプトに「SUNKENLAND」「Sunken Atoll」「Sunkenland」等の固有名を含める
- 「とりあえず」のロゴ試作(後続作業で意識に固着するリスク)
- 商標未調査のキャラクタを SNS / ストア / 外部公開
- メタデータ記録を後回しにして大量生成
- ジャンル参照を超える既存作品の意匠コピー

## 10. 参照

- F-05 発動: `pipeline/escalations/2026-05-05_trademark_search_request.md`
- 全体方針: `pipeline/escalations/2026-05-05_ip_similarity_check.md`
- 規約: `docs/07_governance/ip_policy.md`、`docs/07_governance/licensing.md`、`docs/07_governance/ai_ethics.md`
- データ仕様: `docs/01_architecture/data_flow.md` §4
- ワークフロー: `docs/03_workflows/asset_generation_workflow.md`
- GDD: §1.5、§10
