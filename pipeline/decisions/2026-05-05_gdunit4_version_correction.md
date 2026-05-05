# 2026-05-05 GdUnit4 バージョン採択の修正(v5.0.4 → v6.1.3)

## 状態

- **Accepted**(承認・実施済)
- 本決定は `pipeline/decisions/2026-05-05_version_proposal.md` の GdUnit4 行を **Supersedes**

## 文脈

`pipeline/decisions/2026-05-05_version_proposal.md` および `pipeline/decisions/2026-05-05_initialization_complete.md` で **GdUnit4 v5.0.4** を採択ロックし、`docs/02_services/version_policy.md` §9.1 / `.github/workflows/ci.yml` / 関連ランブックに反映済だった。

GitHub Actions 初回 CI 実行(run id `25353199233`、commit `ddb325e`)で `GdUnit4 (ubuntu-latest)` ジョブが **exit code 78**(Incompatible version combination)で失敗。`MikeSchulze/gdUnit4-action@v1` の互換性マトリクスが以下を示した:

```
✗ Incompatible version combination detected!
  GdUnit4 v5.0.4 supports Godot v4.3 to v4.4.999, but you are using Godot v4.6.2
```

採択時の WebSearch 情報「v5.0.4 は Godot 4.6 対応」は **誤り** だった。公式互換性マトリクス(action 内蔵 JSON)の事実が以下:

| GdUnit4 | 対応 Godot |
|---|---|
| v5.0.x | 4.3 〜 4.4.999 |
| v6.0.x | 4.5 専用 |
| **v6.1.x** | **4.5 〜 4.6.x** ✓ |
| master(v6.2) | 4.5 〜 4.7-beta1 |

## 選択肢

- **A: v6.1.3(v6.1.x 系の最新パッチ)を採用** ✓ 採用
  - 利点: Godot 4.6.2 公式対応、安定パッチ、master(v6.2)が来ても継続的に追従可能
  - 欠点: v5 → v6 でメジャー変更があり、API 差異が存在する可能性(`extends GdUnitTestSuite` 等の基本 API は維持)

- **B: master(v6.2)を採用**
  - 利点: 4.7-beta も視野
  - 欠点: 安定リリース未確定、CI で `git ls-remote` ベースになり再現性が下がる

- **C: Godot を 4.4.x にダウングレード**
  - 利点: GdUnit4 v5.0.4 をそのまま使える
  - 欠点: Jolt 既定化(4.6 から)など本作要件を犠牲にする。`pipeline/decisions/2026-05-05_initialization_complete.md` の根幹を覆す

## 決定

**A: GdUnit4 v6.1.3 を採用**。

### 反映箇所(本決定で更新済)

| ファイル | 変更 |
|---|---|
| `docs/02_services/version_policy.md` §9.1 | テスト行を `v5.0.4` → `v6.1.3`、根拠 URL を `godot-gdunit-labs/gdUnit4` 組織側へ更新、互換性根拠を備考に明記 |
| `docs/02_services/version_policy.md` §9.2 | gdunit4-action 行を「未確定」→「@v1(rolling)」、`version` 入力で `v6.1.3` 指定する旨を備考化 |
| `.github/workflows/ci.yml` env | `GDUNIT4_VERSION: v5.0.4` → `v6.1.3` |
| `pipeline/runbooks/2026-05-05_po_unblock_h01_h06.md` H-02 | ダウンロード URL・ファイル名・互換性注記・トラブルシュートをすべて v6.1.x 系に更新 |

### 反映しなかった箇所(履歴保持)

`08_process/decision_log_protocol.md` §4 不変原則に従い、過去の意思決定ログは原文保持:
- `pipeline/decisions/2026-05-05_version_proposal.md`
- `pipeline/decisions/2026-05-05_initialization_complete.md`
- `pipeline/decisions/2026-05-05_session_handoff.md`
- `pipeline/escalations/2026-05-05_godot_install_required.md`

これらは **本決定により Superseded** された旨を本ファイルが記録することで履歴追跡性を確保。

## 結果

期待される効果:
- CI の `GdUnit4 (ubuntu-latest)` ジョブが緑化(本コミット push 後の run で確認)
- ローカル / CI 双方で Godot 4.6.2 + GdUnit4 v6.1.x の組合せがサポートされる
- 将来の Godot 4.7 リリース時には master(v6.2)系への移行を検討する道が開ける(`F-07` フォローと整合)

リスクと引き換え:
- v5 → v6 でテスト API のごく一部に差異がある可能性 → H-04 import + テスト実行時に検出、必要なら個別修正
- ローカル addon 側にも v6.1.3 の配置を要求(`H-02` 手順を最新化済)

## 学び(再発防止)

- **WebSearch 結果は「業界共通の指標」であり、CI 公式互換性マトリクスとは別** という認識を強化
- バージョン採択決定 PR 段階で、可能な限り **採択候補の対応マトリクスを公式 JSON / 公式 README から確認** する手続を加える
- 本作の場合: `pipeline/decisions/2026-05-05_version_proposal.md` 起票時に gdUnit4-action のリポジトリの `.gdunit4_action/versioning/check/compatibility_matrix.json` を直接参照すべきだった

## フォロー

| # | 作業 | 担当 | トリガ |
|---|---|---|---|
| F-G01 | 本コミット push 後の CI run が緑化することを確認 | Claude Code | push 直後 |
| F-G02 | ローカル addons/gdUnit4/ を v6.1.3 に差替(既存 addon が古い場合) | PO | ローカルテスト実行前 |
| F-G03 | テスト API 差異(v5 → v6.1)で個別失敗があれば修正 | Claude Code | テスト実行結果による |
| F-G04 | Godot 4.7 リリース時の互換性確認(`initialization_complete.md` F-07 と統合) | Claude Code | Godot 4.7 stable 後 |

## 関連

- 親決定: `pipeline/decisions/2026-05-05_version_proposal.md`(本決定が Supersedes)、`pipeline/decisions/2026-05-05_initialization_complete.md`
- CI 失敗 run: <https://github.com/Garoro0920/sunken-atoll/actions/runs/25353199233>
- 互換性マトリクス出典: <https://github.com/godot-gdunit-labs/gdUnit4#compatibility-overview>
- 規約: `docs/02_services/version_policy.md`、`docs/08_process/decision_log_protocol.md`
- 関連エスカレーション: `pipeline/escalations/2026-05-05_godot_install_required.md`(H-02 手順への波及)、`pipeline/runbooks/2026-05-05_po_unblock_h01_h06.md`(H-02 セクションを更新)

## 起票

- 起票日: 2026-05-05
- 起票者: Claude Code(本セッション主担当)
