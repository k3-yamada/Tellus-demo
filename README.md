# Tellus Infrastructure Monitor

富山県内インフラ（常願寺川流域・立山エリア）を対象に、Tellus Satellite Data Traveler API から取得した SAR シーンメタデータを可視化するポートフォリオデモです。

## 機能概要

| 機能 | 説明 |
|------|------|
| **Explorer モード** | サマリーカード、SAR サムネイル、年別観測回数グラフ、footprint ポリゴン |
| **Analyst モード** | 変位デモ、軌道/偏波フィルタ、解析パネル |
| **シナリオ切替** | 堤防 / 斜面 / 梅雨 / 長期 |
| **データカタログ** | 地域別観測件数一覧 |
| **調達デモ** | DEMO_MODE カート dry-run（本番発注なし） |

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
