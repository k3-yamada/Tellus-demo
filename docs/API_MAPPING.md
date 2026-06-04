# Tellus API Mapping

## Traveler API (v1)

Base: `https://www.tellusxdp.com/api/traveler/v1`

| Endpoint | Method | Used By | Purpose |
|----------|--------|---------|---------|
| `/datasets/` | GET | `fetch_tellus_data.py`, BFF | List SAR datasets |
| `/data-search/` | POST | `fetch_tellus_data.py`, BFF | Spatial + temporal search |
| `/datasets/{id}` | GET | `enrich_scenes.py` | Dataset metadata |
| `/data/{id}` | GET | `enrich_scenes.py` | Scene detail |
| `/data/{id}/thumbnails/` | GET | `enrich_scenes.py` | Preview images |
| `/data/{id}/download-url/` | GET | `enrich_scenes.py` | Signed download URL |
| `/cart-items/` | POST | `procurement` (DEMO_MODE) | Mock cart |
| `/dataset-orders/` | POST | `procurement` (DEMO_MODE) | Mock order |

## TelluSAR API

Base: `https://www.tellusxdp.com/api/tellusar/v1`

| Endpoint | Method | Used By | Purpose |
|----------|--------|---------|---------|
| `/jobs/` | POST | `tellusar_jobs.py` | Submit analysis job |
| `/jobs/{id}/` | GET | `tellusar_jobs.py` | Poll job status |

## BFF Routes

| Route | Proxies To |
|-------|-----------|
| `GET /api/datasets` | Traveler `/datasets/` |
| `POST /api/search` | Traveler `/data-search/` |
| `GET /api/datasets/{id}/data/{id}/*` | Traveler scene/thumbnail paths |
| `POST /api/tellusar/jobs` | TelluSAR `/jobs/` |
| `GET /api/tellusar/jobs/{id}` | TelluSAR job status |
| `POST /api/cart-items` | Traveler `/cart-items/` (or dry-run) |
| `POST /api/purchased-data-search` | Traveler `/purchased-data-search/` |

## Authentication

All Tellus calls use `Authorization: Bearer $TELLUS_API_KEY`. The key is never exposed to the browser; only the BFF or local Python scripts hold it.
