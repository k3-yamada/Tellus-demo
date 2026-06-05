# Tellus Infrastructure Monitor

富山の**堤防（常願寺川）**と**斜面（立山室堂）**を例に、Tellus の SAR 衛星データを「取得 → 可視化 → 絞り込み → 調達・解析の入口」まで一通り試せる**参照実装デモ**です。本番の浸水判定や確定変位ではなく、**データが揃っているか・いつ撮れたか・次に何を買って解析するか**を短時間で説明・検証する用途向けです。

## このデモでできること（成果）

| 誰向け | やりたいこと | デモでの体験 |
|--------|----------------|--------------|
| **インフラ・防災担当** | 監視地点の周辺で、いつ衛星が何回撮っているか把握したい | Explorer：地図上の footprint、タイムライン、年別回数、サムネ（93/1000 件）で「観測の厚み」を確認 |
| **解析担当** | 軌道・偏波でシーンを絞り、変位解析の前提を整理したい | Analyst：軌道/偏波フィルタ、変位デモ UI、TelluSAR 候補ペア ID（本番は TelluSAR ジョブ結果に差し替え） |
| **データ運用担当** | 新着シーンを検知し、チームに共有したい | Python：`fetch` → `diff`（`.previous.json`）→ Slack、`thumbnail_manifest` |
| **調達・POC 担当** | API 経由のカート・発注フローを壊さず試したい | 調達デモ：`DEMO_MODE` + BFF の dry-run（実課金なし） |
| **営業・新規顧客** | 「うちの案件にも応用できるか」即座に判別したい | 業界別テンプレ：ダム / 橋梁 / 空港 / 新幹線高架 / 港湾 をヘッダのドロップダウンで切替 |
| **広報・経営層** | 過去の災害で Tellus がどう役立ったか見せたい | 災害アーカイブ：能登半島地震 / 西日本豪雨 / 熱海土砂を before / during / after で並列表示 |
| **SAR 解析者** | precomputed ではなく実 InSAR ジョブを試したい | TelluSAR デモ：BFF dry-run 経由で実投入 → ポーリング → 干渉解析サマリー表示 |
| **GIS / プロダクトオーナー** | Tellus = SAR only の誤解を解きたい | マルチセンサー比較：PALSAR-2 / ASNARO-1 / Landsat を同一地点で横並び |

**5分デモの流れ**（詳細は [docs/SCENARIOS.md](docs/SCENARIOS.md)）  
1. ダッシュボード → サマリーで「わかる/わからない」を確認  
2. 立山を選択 → 地図に footprint、タイムライン操作  
3. Analyst に切替 → フィルタと変位デモ  
4. カタログ / 調達デモ / アーキテクチャ画面でデータ資産と構成を説明  

## わざとやらないこと（誤解防止）

- mm 単位の**確定地盤変位**（Analyst の変位は precomputed デモ）
- 降雨・浸水・被害の**自動判定**（メタデータとサムネの範囲）
- 全 1000 件の画像プレビュー（enrich で段階取得する設計）

## 技術コンポーネント（実装の中身）

| レイヤ | 内容 |
|--------|------|
| **Flutter Web** | Explorer/Analyst、地図、品質サマリー、カタログ、調達 UI |
| **Python** | Traveler API 取得、enrich、diff、TelluSAR ペア選定、通知 |
| **BFF (Workers)** | トークン秘匿、Traveler/TelluSAR/カートのプロキシ |
| **CI** | analyze / test / E2E / 週次 fetch cron |

## ディレクトリ構成

```
Tellus-demo/
├── backend/              # Cloudflare Workers BFF
├── docs/                 # ARCHITECTURE, API_MAPPING, SCENARIOS, schema v2
├── e2e/                  # Playwright E2E
├── infra/github/workflows/  # CI + 週次 fetch cron
├── scripts/              # Python ETL + pipeline
│   ├── tellus_client.py
│   ├── fetch_tellus_data.py
│   └── pipeline/         # enrich, migrate, quality, notify, tellusar
└── web_app/              # Flutter Web ダッシュボード
```

## 前提

- Python 3.10+
- Flutter SDK（Web 有効化済み）
- [Tellus](https://www.tellusxdp.com/) アカウントと API トークン

## クイックスタート

### 1. 環境変数

```bash
cp .env.example .env
# TELLUS_API_KEY を設定
```

| 変数 | 説明 |
|------|------|
| `TELLUS_API_KEY` | Tellus API トークン |
| `BFF_URL` | Cloudflare Workers BFF URL（任意） |
| `DEMO_MODE` | `true` で調達デモ有効 |
| `SLACK_WEBHOOK_URL` | パイプライン通知（任意） |

### 2. データ取得

```bash
cd scripts
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python fetch_tellus_data.py
python pipeline/attach_datasets_catalog.py   # カタログのみ更新
python pipeline/enrich_scenes.py ../web_app/assets/data/infrastructure_data.json 80
python pipeline/select_tellusar_pair.py      # TelluSAR 候補ペア
python pipeline/thumbnail_manifest.py
```

既存 JSON を v2 に移行（再取得不要）:

```bash
python pipeline/migrate_v2.py ../web_app/assets/data/infrastructure_data.json
```

### 3. Flutter Web 実行

```bash
cd web_app
flutter pub get
flutter run -d chrome
```

### 4. 本番ビルド & デプロイ

```bash
cd web_app && flutter build web --release
firebase deploy --only hosting   # firebase.json 参照
```

## スキーマ v2

`infrastructure_data.json` は `schemaVersion: 2` をサポートします。v1 フィールドは後方互換です。

追加フィールド:
- `qualityReport` — データ品質サマリー
- `coverageByYear` — 地域×年別観測回数
- `meta.displacementDemo` — 立山斜面の変位デモ（Analyst 用、本解析値ではない）
- 観測ごと: `geometry`, `thumbnailUrl`, `qualityScore`

詳細: [docs/schema/infrastructure_data.v2.json](docs/schema/infrastructure_data.v2.json)

## BFF (Cloudflare Workers)

```bash
cd backend
npm install
wrangler secret put TELLUS_API_KEY
npm run dev
```

| ルート | 説明 |
|--------|------|
| `GET /api/datasets` | Traveler datasets プロキシ |
| `POST /api/search` | Traveler data-search プロキシ |
| `GET /health` | ヘルスチェック |
| `GET /api/datasets/{id}/data/{id}/*` | シーン・サムネプロキシ |
| `POST /api/tellusar/jobs` | TelluSAR ジョブ投入 |
| `POST /api/purchased-data-search` | 購入済み検索 |
| `POST /api/cart-items` | カート（dry-run 対応） |
| `POST /api/dataset-orders` | 発注（dry-run 対応） |

## テスト

```bash
# Dart
cd web_app && dart analyze && flutter test

# Python
cd scripts && python -m pytest tests/ -v

# E2E
cd web_app && flutter build web --release
cd ../e2e && npm ci && npx playwright install chromium && npm test
```

## monitoringIndex について

チャート・マーカー色に使う `monitoringIndex` は API メタデータ（`view:off_nadir` 等）を正規化した**デモ用指標**です。地盤変位や浸水の実解析値ではありません。

## TelluSAR（任意）

```bash
cd scripts
# meta.tellusarSuggestedPair の ID でジョブ投入
python pipeline/tellusar_jobs.py --from-json
# 完了後、結果 JSON を displacementDemo にマージ
python pipeline/merge_tellusar_result.py ../web_app/assets/data/infrastructure_data.json job_result.json
```

## ドキュメント

- [ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [API_MAPPING.md](docs/API_MAPPING.md)
- [SCENARIOS.md](docs/SCENARIOS.md)
- [実装計画](.planning/TELLUS_FULL_IMPLEMENTATION_PLAN.md)

## 対象地域

- **常願寺川流域**（佐々堤付近）: 36.598°N, 137.340°E — 堤防
- **立山室堂**（斜面）: 36.577°N, 137.596°E — 斜面

## CI

GitHub Actions (`infra/github/workflows/`):
- **ci.yml** — flutter analyze, test, build web, pytest, Playwright E2E
- **fetch-cron.yml** — 週次データ取得 + Slack 通知
