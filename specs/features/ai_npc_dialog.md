# Spec: LLM 駆動 NPC 対話

| 項目 | 内容 |
|---|---|
| 状態 | Draft(実験的) |
| 親 GDD | `specs/game_design_document.md` §1.3 / §2.5 |
| 起票日 | 2026-05-05 |
| 関連 | `docs/02_services/service_catalog.md` L10、`docs/05_claude_code/prompt_engineering_guide.md` §15、`docs/07_governance/ai_ethics.md` §6 |

## 1. 目的

主要 NPC(派閥代表・特殊商人など限定数)に **ランタイム LLM** を統合し、固定スクリプトでは難しい派閥取引・噂・状況依存の応答を実現する。雑魚 NPC は固定スクリプトのまま、コスト・遅延を抑える。

## 2. ユーザストーリー

- プレイヤーとして、主要 NPC との会話で「世界が動いている」感覚を得たい。
- 開発者として、NPC の人格・世界観を JSON で管理し、コード変更なしで調整したい。
- 運用者として、API コスト・レイテンシ・不適切応答を継続監視したい。

## 3. 要件

### 3.1 適用範囲

- **LLM 駆動**: 派閥代表 NPC(MVP は 2 種)、特殊商人(MVP は 1 種)
- **固定スクリプト**: 雑魚海賊・通行人・チュートリアル NPC(MVP の大半)
- 切替判断: NPC 定義の `dialog_mode: "scripted" | "llm"` フィールド

### 3.2 採用 LLM

- 第一候補: Anthropic Claude(`docs/02_services/service_catalog.md` L0)
- 代替: OpenAI(フェイルオーバー)
- モデル ID は `docs/02_services/version_policy.md` で確定後ロック

### 3.3 プロンプト構造

`docs/05_claude_code/prompt_templates.md` §4.9 と `prompt_engineering_guide.md` §15 に準拠。

```
[system]
あなたは <キャラ名>。
- 立場: <派閥/役割>
- 性格: <性格>
- 背景: <世界観・履歴>
- 口調: <文体例>
- 知識: <知っていること>
- 禁止: 世界観外の知識、プレイヤー個人情報の記憶、暴力的・差別的応答
- 形式: 1 応答 80 文字以内、日本語(プレイヤー言語に追従)

[context]
- 派閥関係: { player_reputation: <数値>, recent_events: [...] }
- 場所: <現在地>
- 時刻: <ゲーム内時刻>

[history]
直近 N ターンの会話(要約圧縮)

[user]
<プレイヤー入力>
```

### 3.4 安全フィルタ

- 入力サニタイズ: プレイヤー入力の引用を二重引用 + サニタイズ
- 出力フィルタ: 暴力 / 性的 / 差別 / 個人情報の事後検知 → 該当時は固定的な「拒否応答」へフォールバック
- ジェイルブレイク試行に対する応答方針(`prompt_engineering_guide.md` §14)
- 子供向け配信時の追加ガード(該当時)

### 3.5 メモリ・コンテキスト

- セッション内: 直近 N ターン(N=10 目安)+ 関係性パラメータ
- セッション間: **NPC は基本的にプレイヤー個人を覚えない**(プライバシー配慮、`docs/07_governance/ai_ethics.md` §6)
- 例外: 派閥関係パラメータのみ永続(これは LLM の記憶ではなくゲーム側の数値)

### 3.6 コスト・レイテンシ管理

- レスポンス目標: < 2 秒(初期トークン)、< 5 秒(完了)
- 同時会話セッション数: ホスト全体で 4(同一ホスト内のプレイヤーが個別 NPC と並行会話する場合)
- 1 セッション当たりトークン上限を設定 → 超過時は固定応答へ
- API 呼出ログは `pipeline/api_calls/` に redacted で記録(`docs/02_services/api_integration_guide.md` §8)
- 高単価 API 呼出は人間承認のフロー(`docs/05_claude_code/collaboration_guide.md` §6)を運用にも適用

### 3.7 オフライン / 障害時

- ネット切断 / API 障害時はフォールバック固定応答
- フェイルオーバー: 第一プロバイダ → 第二プロバイダ → 固定応答
- 監視: 失敗率閾値超過で `incident_response_workflow.md` 起動

### 3.8 ローカライズ

- プレイヤー言語に追従(MVP: 日本語 / 英語)
- LLM への言語指示はシステムプロンプトに含める
- TTS 統合は別 spec(`specs/features/voice_synthesis.md` 予定、MVP 後)

### 3.9 テスト観点

- 単体: プロンプト構築、出力パーサ、フォールバック
- 統合: モック LLM での会話フロー
- 安全: 既知のジェイルブレイクプロンプト集に対する適切な応答(独立評価セット)
- パフォーマンス: 同時 4 セッションでのレイテンシ
- コスト: 1 ゲームセッション(2 時間)の平均コストを計測

## 4. 非要件 / スコープ外

- ボイス合成(TTS)は別 spec
- リップシンク(Audio2Face)は別 spec
- NPC の長期記憶(セッション間継続)は MVP 外
- プレイヤー個人化(プレイヤー履歴の記憶)は **プライバシー上禁止**

## 5. 受入基準(DoD)

- [ ] 主要 NPC 3 種(派閥代表 2 + 特殊商人 1)が LLM 駆動で会話可能
- [ ] フォールバック(API 障害 / コスト上限 / 不適切応答検知)が動作
- [ ] 安全フィルタが既知ジェイルブレイクに対して 95% 以上で適切応答
- [ ] 平均レイテンシ目標達成
- [ ] API 呼出ログが redacted で記録
- [ ] ローカライズ(日 / 英)動作
- [ ] AI 倫理ガイドライン(`docs/07_governance/ai_ethics.md`)準拠の確認

## 6. 想定実装

- 配置: `src/ai/llm_npc/`、`pipeline/prompts/templates/npc/`、`resources/data/npc/`
- 触ってよいパス: 上記 + `tests/integration/llm_npc/`、`pipeline/api_calls/`(ログのみ)
- 触らないパス: `src/networking/` 基盤、シークレット類

## 7. リスクと未決事項

| リスク | 対策 |
|---|---|
| 不適切応答(差別 / 暴力 / 倫理逸脱) | 多層フィルタ + 監視 + 即時固定応答フォールバック |
| API コスト超過 | セッション内トークン上限、月次予算アラート |
| API 障害 | フェイルオーバー + オフライン固定応答 |
| プロンプトインジェクション | 入力サニタイズ + システムプロンプトの強化 |
| プレイヤー音声入力(将来) | MVP では対象外 |
| LLM の世界観逸脱(幻覚) | システムプロンプトに知識制約、不一致検知 |

## 8. 参照

- GDD: §1.3、§2.5
- `docs/02_services/service_catalog.md` L10
- `docs/02_services/api_integration_guide.md`
- `docs/02_services/secrets_management.md`
- `docs/05_claude_code/prompt_templates.md` §4.9
- `docs/05_claude_code/prompt_engineering_guide.md` §14、§15
- `docs/07_governance/ai_ethics.md` §6
- `docs/03_workflows/incident_response_workflow.md`
