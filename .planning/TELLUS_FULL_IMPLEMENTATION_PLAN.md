# Tellus Infrastructure Monitor — 全機能再現 実装計画

> 目的: 前回整理した UX 改善・Traveler API フル活用・TelluSAR 解析・運用パイプライン・
> 商用ワークフローデモを **ポートフォリオとして再現可能な形** で完成させる。

## 0. ゴール定義

### 完成像（Done の状態）

| レイヤ | 完成条件 |
|--------|----------|
| **データ** | Traveler 全主要フロー（検索→詳細→サムネ→DL URL）+ TelluSAR ジョブ結果 + 品質レポート JSON |
| **バックエンド** | API キーを秘匿する BFF、定期バッチ、新着検知、通知（Slack/Webhook） |
| **フロント** | Explorer / Analyst モード、footprint・サムネ・変位レイヤ、シナリオ切替 |
| **運用** | GitHub Actions cron、E2E + API 契約テスト、README/Architecture ドキュメント |
| **誠実性** | デモ値と本解析値の区別、有償/無料境界、商用注意の UI 明示 |

### 非ゴール

- 本番 SLA・マルチテナント認証
- 有償データの自動購入（発注 API は **デモモード** のみ）
- Tellus 解析環境（JupyterLab / QGIS）のホスティング
- 全 Tellus ツールの完全統合（TelluSAR 優先、Clairvoyant 等は Phase 4 任意）

---

## 1. ターゲットアーキテクチャ

```
Flutter Web (Hosting)
    ↓ HTTPS
BFF (Cloudflare Workers 推奨)
    ↓
GitHub Actions cron → Python pipeline → R2/GCS
    ↓
Tellus: Traveler API + TelluSAR API
```

### 最終ディレクトリ構成

```
Tellus-demo/
├── .planning/                 # 本計画
├── backend/                   # BFF (Workers)
├── scripts/pipeline/          # ETL, TelluSAR, quality, notify
├── web_app/lib/ui/features/
│   ├── explorer/ analyst/ catalog/ procurement/ architecture/
├── e2e/
├── infra/github/workflows/
└── docs/ (ARCHITECTURE, API_MAPPING, SCENARIOS)
```

---

## 2. フェーズ概要

| Phase | 名称 | 目安 | 依存 |
|-------|------|------|------|
| **0** | 基盤・スキーマ v2 | 3–5 日 | — |
| **1** | 見える化 + Explorer UX | 5–8 日 | 0 |
| **2** | TelluSAR + 品質フィルタ | 5–10 日 | 1 |
| **3** | BFF + cron + 通知 | 5–8 日 | 1 |
| **4** | 商用デモ + マルチモーダル | 4–6 日 | 3 |
| **5** | テスト・ドキュメント | 3–5 日 | 1–4 |

**合計: 25–42 人日（1人で 5–8 週間）** — Phase 2 と 3 は並行可。

---

## 3. Phase 0 — 基盤

**タスク**
- JSON スキーマ v2（footprint, thumbnails, qualityScore, displacement）
- Domain モデル拡張、Repository を static/remote 二系統化
- `scripts/tellus_client.py` 共通化、`.env.example` 拡張

**完了条件**: 既存 UI 後方互換、`dart analyze` グリーン、v2 空 JSON 出力

---

## 4. Phase 1 — 見える化（Traveler フル）

### Python
- enrich: `GET datasets/{id}`, `GET data/{id}`, thumbnails + download-url
- geometry を JSON 保持、`quality_report.py`

### Flutter
- SummaryCard（わかる/わからない）
- Explorer / Analyst トグル
- Map footprint (PolygonLayer)、ThumbnailPreview
- 日本語日付、年別観測回数棒グラフ
- CatalogPage、スライダー年ラベル + 再生

### E2E: サマリー・サムネ・スライダー smoke

---

## 5. Phase 2 — 解析（TelluSAR）

- TelluSAR API クライアント（別 namespace）
- ペア選定: relativeOrbit + 偏波 + 時間間隔
- ジョブ投入→ポーリング→mm 変位 or タイル URL
- UI: AnalysisPanel、変位凡例、軌道/偏波フィルタ
- シナリオ: embankment / slope / rainy-season / long-term
- monitoringIndex は Analyst の「レガシーデモ」のみ

**完了**: 立山 1 ペア以上表示（precomputed 可）、Disclaimer 常時

---

## 6. Phase 3 — 運用

### BFF ルート
- `/api/datasets`, `/api/search`, `/api/scenes/*`
- `/api/tellusar/jobs`, `/api/aoi`, `/api/search-conditions`

### GitHub Actions
- 週次 fetch + enrich + diff 新着 → Slack

### ストレージ
- サムネ R2 ミラー、Flutter は CDN URL

**完了**: ブラウザに API キー非露出、cron 手動成功

---

## 7. Phase 4 — 商用 + マルチモーダル

- cart-items / dataset-orders（DEMO_MODE dry-run）
- purchased-data-search タブ
- 光学 dataset 切替（任意）
- Architecture ページ（Mermaid + Tech stack）

---

## 8. Phase 5 — 品質

- flutter test / pytest 契約 / Playwright 拡張 / BFF smoke
- docs: ARCHITECTURE, API_MAPPING, SCENARIOS
- README スクリーンショット、CI 完備

---

## 9. Traveler API チェックリスト

datasets, dataset detail, terms/manual URL, data-search, scene detail,
thumbnails+download-url, files, archived-file-downloads,
purchased-data-search, interest-areas, search-conditions,
cart-items, dataset-orders (デモ)

---

## 10. リスク

| リスク | 対策 |
|--------|------|
| 503/レート制限 | retry + incremental enrich |
| サムネ期限 | R2 ミラー |
| TelluSAR 遅延 | precomputed + 進捗 UI |
| 誤発注 | DEMO_MODE + dry-run |
| 大 JSON | chunk / BFF pagination |

---

## 11. マイルストーン

- **M1** (2週): Phase 0+1 — 見える
- **M2** (+2週): Phase 2 — 解析
- **M3** (+1.5週): Phase 3 — 運用
- **M4** (+1.5週): Phase 4+5 — 提案資料完成

---

## 12. 最初の 5 PR

1. `feat/schema-v2` — Phase 0
2. `feat/enrich-scenes` — Python enrich
3. `feat/explorer-ui` — SummaryCard, モード切替
4. `feat/map-footprint-thumbnail` — 地図+サムネ
5. `feat/e2e-phase1` — E2E + README

---

## 13. 成功指標

1. 5 分デモで履歴→サムネ→footprint→変位→新着を説明
2. README のみで再現可能
3. Traveler Swagger 主要リソース 80%+ をコード参照
4. Explorer/Analyst 同一 URL
5. CI green (lint, test, build, E2E)

---

*2026-06-04 · 次: Phase 0 PR-1*
