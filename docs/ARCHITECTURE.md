# Tellus Infrastructure Monitor — Architecture

## Overview

Flutter Web dashboard visualizing SAR satellite metadata from Tellus Traveler API for infrastructure monitoring in Toyama Prefecture.

```
┌─────────────────┐     HTTPS      ┌──────────────────┐
│  Flutter Web    │ ──────────────▶│  BFF (Workers)   │
│  (Firebase)     │                │  /api/*          │
└────────┬────────┘                └────────┬─────────┘
         │ assets/data/*.json               │ Bearer token
         │ assets/images/*                  ▼
         ▼                          ┌──────────────────┐
┌─────────────────┐                │  Python Pipeline │
│  Static JSON +  │◀── cron ──────│  fetch + enrich  │
│  bundled PNGs   │                │  + generate_*    │
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
| Pipeline | `scripts/` | ETL, quality reports, TelluSAR jobs, bundled PNG generation |
| BFF | `backend/` | API key proxy for browser clients |

## Data Flow

1. **Fetch**: `fetch_tellus_data.py` queries Traveler `data-search` per region BBOX.
2. **Enrich** (optional, live): `pipeline/enrich_scenes.py` adds Tellus signed `thumbnailUrl` values and download URLs (~1h expiry).
3. **Bundled thumbnails** (offline demo default): `demo_png.py` helpers + `generate_sar_thumbnails.py`, `generate_industry_templates.py`, `generate_disaster_archive.py`, `generate_multi_sensor.py` emit synthetic PNGs under `web_app/assets/images/` and patch JSON `thumbnailUrl` to `assets/images/...`.
4. **Migrate**: `pipeline/migrate_v2.py` adds schemaVersion, qualityReport, coverageByYear.
5. **Serve**: Flutter loads bundled JSON + images; `ThumbnailPreview` uses `Image.asset` for `assets/` paths, `Image.network` for signed URLs, with `sar_fallback.png` on failure.

### Bundled image assets

| Directory | Generator | Consumer |
|-----------|-----------|----------|
| `assets/images/sar/` | `generate_sar_thumbnails.py` | Dashboard (joganji / tateyama) |
| `assets/images/templates/{id}/` | `generate_industry_templates.py` | Template switcher → Dashboard |
| `assets/images/disaster/` | `generate_disaster_archive.py` | Disaster archive (`DisasterPhasePreview`) |
| `assets/images/multi_sensor/` | `generate_multi_sensor.py` | Multi-sensor comparison |
| `assets/images/demo/sar_fallback.png` | static | `ThumbnailPreview` network/error fallback |

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
