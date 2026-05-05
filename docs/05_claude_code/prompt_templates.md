# プロンプトテンプレート集

## 1. 目的

Claude Code が外部 API へ送るプロンプトと、人間 → Claude Code への指示の **再利用可能なテンプレート** を集約する。具体値はプロジェクト開始時に埋める。

## 2. テンプレート利用時の作法

- テンプレートはあくまで **下敷き**。プロジェクトに合わせて編集する
- 具体的なバージョン名・モデル名は埋め込まない(`02_services/version_policy.md` の値を環境変数経由で参照)
- 確定したテンプレートは `pipeline/prompts/templates/` にコミット

## 3. 人間 → Claude Code テンプレート

### 3.1 仕様起票
```
[目的] <一文で>
[ユーザストーリー] <ロールとして、〜したい、なぜなら〜>
[範囲] 含む / 含まない を箇条書き
[受入基準] 具体的に観測可能な条件
[制約] 性能・期限・予算
[参照] 関連 spec / docs / Issue
```

### 3.2 機能実装依頼
```
@implement 仕様 <path> に基づいて実装してください。
- 触ってよいパス: <列挙>
- 触らないパス: <列挙>
- テスト追加: 単体 + シナリオ
- ドキュメント更新: 該当する規約・ワークフローに反映
- 完了報告に変更点・次の一歩を含めてください。
```

### 3.3 アセット生成依頼(Claude Code に指示)
```
@assets 次のアセットを生成してください。
- 種別: mesh / texture / animation / audio / voice
- 用途: <用途>
- 仕様: <ポリ数 / 解像度 / 尺 / スタイル>
- ライセンス: 商用可
- 出力先: assets/raw/<kind>/
- 完了後、メタデータと再インポートまで実施。
```

### 3.4 検証依頼
```
@verify 次の観点で <対象> を検証してください。
- 規約準拠: 04_standards/* と整合
- 性能: 現行ベースラインから劣化なし
- 視覚: 主要シーンに視覚異常なし
- テスト: 全 G1/G2 ゲートが緑
レポートを 1 ページ以内で。
```

### 3.5 障害対応開始
```
@incident <検知内容>
- Sev 仮判定: <Sev>
- 一次封じ込めの提案
- 影響評価
- 根本原因仮説 上位 3 つ
incident_response_workflow に従ってください。
```

## 4. Claude Code → 外部 API テンプレート

### 4.1 3D メッシュ(共通骨子)
```
{
  "model": "${MESH_MODEL}",
  "prompt": "<オブジェクト名>, <スタイル>, <構造的特徴>",
  "negative": "low quality, broken topology, asymmetric where unintended",
  "polycount_target": ${POLYCOUNT_TARGET},
  "with_rig": true|false,
  "with_textures": true,
  "seed": ${SEED}
}
```

### 4.2 テクスチャ(SD 系経路)
```
{
  "model": "${IMAGE_MODEL}",
  "prompt": "<対象> texture, seamless, tileable, PBR, <スタイル>",
  "negative": "watermark, text, signature",
  "size": "2048x2048",
  "seed": ${SEED}
}
```

### 4.3 HDRI スカイ
```
{
  "model": "${SKYBOX_MODEL}",
  "prompt": "<時間帯> <天候> <場所>, equirectangular, HDR",
  "size": "8192x4096",
  "seed": ${SEED}
}
```

### 4.4 アニメーション(text → motion)
```
{
  "model": "${MOTION_MODEL}",
  "prompt": "<キャラ> <動作の自然言語記述>",
  "duration_sec": 2.5,
  "loop": true|false,
  "fps": 30,
  "rig": "humanoid_standard",
  "seed": ${SEED}
}
```

### 4.5 SFX
```
{
  "model": "${SFX_MODEL}",
  "prompt": "<音の説明>, <長さ>, <空間特徴>",
  "duration_sec": 2.0,
  "loop": true|false,
  "format": "ogg"
}
```

### 4.6 BGM
```
{
  "model": "${MUSIC_MODEL}",
  "prompt": "<シーン> <ジャンル> <雰囲気> <楽器構成>",
  "tempo": 120,
  "duration_sec": 90,
  "loopable": true,
  "stems": false
}
```

### 4.7 TTS(キャラ)
```
{
  "model": "${TTS_MODEL}",
  "voice": "${VOICE_ID_BLACKSMITH}",
  "text": "<セリフ>",
  "language": "ja-JP",
  "stability": 0.5,
  "similarity": 0.7,
  "format": "ogg"
}
```

### 4.8 Vision 解析(視覚回帰)
```
このスクリーンショットを評価してください。
- 想定: <シーン名>、想定の見た目
- 検出対象:
  1. ピンク/紫マテリアル(欠損)
  2. 黒/白の極端領域
  3. メッシュ崩壊
  4. UI 切れ・重なり
  5. Z-fighting
出力 JSON:
{
  "issues": [{"type":"...", "region":"...", "confidence":0.0-1.0}],
  "overall_pass": true|false,
  "notes": "..."
}
```

### 4.9 NPC ランタイム(LLM)
```
[system]
あなたは <キャラ名>。性格: <性格>。背景: <背景>。
ルール:
- 世界観に反する発言は避ける
- 1 応答 80 文字以内
- 不適切表現を避ける
[user]
<プレイヤー入力>
```

## 5. プロンプト品質ガイド

- **狙いを明示**: 「dragon, dark fantasy, scarred, perched」のように属性を列挙
- **negative を活用**: 排除したい特徴を明示
- **再現性のためシード固定**
- **冗長な賛辞や曖昧語を避ける**(masterpiece などの薄い語)
- **言語の選択**: モデルが英語学習中心なら英語プロンプトが安定する

## 6. プロンプト履歴

- すべての本番プロンプトは `pipeline/prompts/<id>.json` に保存
- 失敗の分析や再現に必須

## 7. 改訂

- テンプレート改善は `pipeline/prompts/templates/` の Git 履歴で追跡
- 大規模改訂は `00_overview/document_index.md` に記録

## 8. 参照
- 共同開発: `05_claude_code/collaboration_guide.md`
- プロンプト設計: `05_claude_code/prompt_engineering_guide.md`
- API 統合: `02_services/api_integration_guide.md`
- アセット生成: `03_workflows/asset_generation_workflow.md`
