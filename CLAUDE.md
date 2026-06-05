# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Tellus Infrastructure Monitor — a Flutter Web reference-implementation demo that visualizes Tellus SAR satellite metadata for two infrastructure sites in Toyama (常願寺川 embankment, 立山室堂 slope). It is a "data availability + procurement on-ramp" demo, **not** a production analytics tool. Displacement values and `monitoringIndex` are precomputed demo values, not real analysis results.

The system has four cooperating components:

- **`web_app/`** — Flutter Web frontend (Firebase Hosting target). Loads `assets/data/infrastructure_data.json` at runtime; in production it can also talk to the BFF.
- **`backend/`** — Cloudflare Workers BFF that proxies Tellus Traveler + TelluSAR APIs and hides `TELLUS_API_KEY` from the browser. Supports `X-Demo-Dry-Run` for cart/order endpoints when `DEMO_MODE=true`.
- **`scripts/`** — Python 3.10+ ETL pipeline: fetch → enrich → migrate(v2) → quality report → TelluSAR pair selection → diff/notify. Outputs feed `web_app/assets/data/`.
- **`e2e/`** — Playwright tests run against a built Flutter Web bundle.

## Common Commands

### Flutter Web (`web_app/`)
```bash
flutter pub get
flutter run -d chrome                      # dev (Chrome)
dart analyze                               # CI uses --fatal-infos
flutter test                               # unit + widget tests
flutter test test/dashboard_view_model_test.dart   # single test file
flutter test --name "regex"                # single test by name
flutter build web --release                # output → build/web (served by Firebase)
```

### Python pipeline (`scripts/`)
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

python fetch_tellus_data.py                              # fetch from Traveler API
python pipeline/enrich_scenes.py ../web_app/assets/data/infrastructure_data.json 80
python pipeline/migrate_v2.py ../web_app/assets/data/infrastructure_data.json
python pipeline/attach_datasets_catalog.py
python pipeline/select_tellusar_pair.py
python pipeline/thumbnail_manifest.py
python pipeline/quality_report.py

# Bundled demo thumbnails (stdlib PNG, no API key)
python pipeline/generate_sar_thumbnails.py          # dashboard joganji/tateyama
python pipeline/generate_industry_templates.py      # industry templates + PNGs
python pipeline/generate_disaster_archive.py        # disaster archive phases
python pipeline/generate_multi_sensor.py            # multi-sensor comparison

python -m pytest tests/ -v                               # all pipeline tests
python -m pytest tests/test_quality_report.py -v         # single file
python -m pytest tests/ -k "tellusar" -v                 # by keyword
```

### BFF (`backend/`)
```bash
npm install
npm run typecheck                          # tsc --noEmit
npm run dev                                # wrangler dev (local Worker)
wrangler secret put TELLUS_API_KEY         # required before deploy
npm run deploy                             # wrangler deploy
```

### E2E (`e2e/`) — requires a built web bundle
```bash
# from web_app/
flutter build web --release
# then from e2e/
npm ci && npx playwright install chromium
npm test                                   # all specs
npx playwright test dashboard.spec.ts      # single spec
npx playwright test --headed               # debug visible
```

### Deploy
```bash
cd web_app && flutter build web --release
firebase deploy --only hosting             # config in firebase.json
```

## Architecture

### Flutter app layering (`web_app/lib/`)
Strict separation; do not bypass layers:

- `ui/features/<feature>/` — `views/`, `view_models/`, `widgets/`. State via `provider` (`ChangeNotifierProvider` wired in `main.dart`).
- `ui/core/theme/` — `CommandCenterTheme` (dark theme, single source).
- `domain/models/` — pure Dart models (`Region`, `Observation`, `InfrastructureSnapshot`, `SarDatasetEntry`, `DisplacementDemo`, `TimelineStep`, `QualityReport`).
- `domain/repositories/` — repository interfaces.
- `data/repositories/` — implementations (currently `InfrastructureRepositoryImpl` parses both v1 and v2 JSON; tolerates legacy field aliases like `lon`/`lng`, `infrastructureType`/`type`, `start_datetime`/`acquisitionDate`).
- `data/services/` — `AssetDataSource` (bundled JSON) and `TellusBffClient` (live BFF).

Features: `dashboard` (Explorer + Analyst modes), `catalog`, `architecture`, `procurement`.

### Data contract (`web_app/assets/data/infrastructure_data.json`)
`schemaVersion: 2` adds `qualityReport`, `coverageByYear` (region→year→count), per-observation `geometry`/`thumbnailUrl`/`qualityScore`, and `meta.displacementDemo`, `meta.datasetsCatalog`, `meta.tellusarSuggestedPair`. **v1 remains supported** — the repository normalizes both. Update `docs/schema/infrastructure_data.v2.json` when changing the shape.

The fixed region order is `['joganji', 'tateyama']` (enforced in `InfrastructureRepositoryImpl`); other regions append after.

### Pipeline data flow
1. `fetch_tellus_data.py` queries Traveler `data-search/` per region BBOX → writes `infrastructure_data.json`.
2. `pipeline/enrich_scenes.py` adds thumbnails (Tellus signed URLs, ~1h TTL) and download URLs (rate-limited; takes count arg).
3. `pipeline/migrate_v2.py` is idempotent — upgrades v1 in place to v2 without re-fetching.
4. `pipeline/diff_observations.py` compares against `.previous.json` for change-detection (Slack via `notify.py`).
5. `pipeline/select_tellusar_pair.py` picks an InSAR pair → `meta.tellusarSuggestedPair`. `tellusar_jobs.py` submits jobs; `merge_tellusar_result.py` merges results back into `displacementDemo`.
6. **Bundled thumbnails** (offline demo default): `demo_png.py` + `generate_sar_thumbnails.py` / `generate_industry_templates.py` / `generate_disaster_archive.py` / `generate_multi_sensor.py` write synthetic PNGs under `web_app/assets/images/` and set `thumbnailUrl` to `assets/images/...`. Flutter `ThumbnailPreview` uses `Image.asset` for those paths; network failures fall back to `assets/images/demo/sar_fallback.png`.

### BFF (`backend/src/index.ts`)
Single-file Worker. Adds Bearer auth, CORS, and `X-Demo-Dry-Run` for `/api/cart-items` and `/api/dataset-orders` (returns mock 200 without calling billing). TelluSAR routes are computed by string-replacing `/traveler/v1` → `/tellusar/v1` from `TELLUS_API_BASE`. See `docs/API_MAPPING.md` for the full route table.

### CI (`infra/github/workflows/`)
- `ci.yml` — four parallel jobs: `flutter` (analyze + test + build), `python` (pytest), `e2e` (needs flutter; builds web then Playwright), `backend` (typecheck). All run on push/PR to `main`/`master`.
- `fetch-cron.yml` — weekly fetch + Slack notification.

## Conventions Specific to This Repo

- **Schema migrations are additive and idempotent.** When adding a field, update `migrate_v2.py` so old JSON upgrades cleanly, and keep the v1-tolerant fallbacks in `InfrastructureRepositoryImpl._parseRegion`.
- **Demo-only values must be labeled.** `monitoringIndex` and `displacementDemo` are precomputed; surface a disclaimer in the UI rather than presenting them as analysis output. The README's "わざとやらないこと" section is the source of truth for scope boundaries.
- **`TELLUS_API_KEY` never reaches the browser** — Flutter code must go through `TellusBffClient` (which calls the Workers BFF), never the Tellus API directly. Python scripts may use the key locally.
- **Region IDs `joganji` and `tateyama` are load-bearing** — used as map keys throughout JSON, view models, and tests. Don't rename without sweeping the pipeline + tests + fixtures.
- **Localization**: default locale is `ja`; UI strings and commit messages are Japanese. `intl` is initialized for `ja` in `main.dart`.
- **Flutter version**: `sdk: ^3.10.7`. No code generation (`build_runner`, `freezed`, `riverpod_generator`) is in use — models are hand-written.

## Key Documentation
- `README.md` — full quickstart, env vars, BFF route table
- `docs/ARCHITECTURE.md` — layer/data-flow diagram
- `docs/API_MAPPING.md` — Tellus endpoint → BFF route mapping
- `docs/SCENARIOS.md` — demo scenario enum and 5-minute demo script
- `docs/schema/infrastructure_data.v2.json` — JSON schema
- `.planning/TELLUS_FULL_IMPLEMENTATION_PLAN.md` — implementation plan
