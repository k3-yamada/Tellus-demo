# Tellus Infrastructure Monitor — Architecture

## Overview

Flutter Web dashboard visualizing SAR satellite metadata from Tellus Traveler API for infrastructure monitoring in Toyama Prefecture.

```
┌─────────────────┐     HTTPS      ┌──────────────────┐
│  Flutter Web    │ ──────────────▶│  BFF (Workers)   │
│  (Firebase)     │                │  /api/*          │
└────────┬────────┘                └────────┬─────────┘
         │ assets/data/*.json               │ Bearer token
         ▼                                  ▼
┌─────────────────┐                ┌──────────────────┐
│  Static JSON    │◀── cron ──────│  Python Pipeline │
│  (v2 schema)    │                │  fetch + enrich  │
└─────────────────┘                └────────┬─────────┘
                                          │
                                          ▼
                                 ┌──────────────────┐
                                 │ Tellus Traveler  │
                                 │ + TelluSAR API   │
                                 └──────────────────┘
```

## Layers

| Layer | Path | Responsibility |
|-------|------|----------------|
| UI | `web_app/lib/ui/` | Explorer/Analyst modes, map, charts, catalog |
| Domain | `web_app/lib/domain/` | Models, repository contracts |
| Data | `web_app/lib/data/` | Asset loading, JSON parsing |
| Pipeline | `scripts/` | ETL, quality reports, TelluSAR jobs |
| BFF | `backend/` | API key proxy for browser clients |

## Data Flow

1. **Fetch**: `fetch_tellus_data.py` queries Traveler `data-search` per region BBOX.
2. **Enrich** (optional): `pipeline/enrich_scenes.py` adds thumbnails, download URLs.
3. **Migrate**: `pipeline/migrate_v2.py` adds schemaVersion, qualityReport, coverageByYear.
4. **Serve**: Flutter loads `assets/data/infrastructure_data.json` or BFF endpoint.

## Schema Versions

- **v1** (legacy): regions, observations, timeline, meta — still supported.
- **v2**: adds `schemaVersion`, `qualityReport`, `coverageByYear`, observation `geometry`, `thumbnailUrl`, `qualityScore`.

## View Modes

- **Explorer**: Summary cards, thumbnails, coverage chart, footprint polygons.
- **Analyst**: Displacement demo, orbit/polarization filters, analysis panel.

## Deployment

- **Frontend**: Firebase Hosting (`web_app/build/web`)
- **BFF**: Cloudflare Workers (`backend/`)
- **Cron**: GitHub Actions (`infra/github/workflows/fetch-cron.yml`)
