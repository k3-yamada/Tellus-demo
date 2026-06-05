# Demo Scenarios

## Regions

| ID | Name | Type | Coordinates |
|----|------|------|-------------|
| `joganji` | 常願寺川流域（佐々堤付近） | embankment | 36.598, 137.340 |
| `tateyama` | 立山室堂（斜面） | slope | 36.577, 137.596 |

## DemoScenario Enum

| Scenario | Description | Default Region |
|----------|-------------|----------------|
| `embankment` | 堤防監視 — 常願寺川流域 | joganji |
| `slope` | 斜面監視 — 立山室堂 | tateyama |
| `rainySeason` | 梅雨期重点 — 両地域、夏季フィルタ | joganji |
| `longTerm` | 長期トレンド — 直近90日（最新観測から遡る） | joganji |

## Displacement Demo

`meta.displacementDemo` in v2 JSON provides precomputed mm displacement values for tateyama region. This is **not** real TelluSAR output — it demonstrates Analyst mode UI only.

## Procurement Demo

When `DEMO_MODE=true`, the procurement page simulates cart and order flows without calling real Tellus billing APIs.

## Industry Templates

Header dropdown switches `infrastructure_data.json` → `assets/data/templates/{dam,bridge,airport,shinkansen,port}.json`. Each observation has a bundled `thumbnailUrl` under `assets/images/templates/{id}/`. Values are synthesized; disclaimer in `meta.disclaimer`.

## Disaster Archive

Three events (能登半島地震 / 西日本豪雨 / 熱海土砂) with before / during / after phases. Phase images are bundled SAR-style PNGs in `assets/images/disaster/`; `DisasterPhasePreview` displays them offline.

## Multi-Sensor Comparison

Side-by-side PALSAR-2, ASNARO-1 optical, and Landsat scenes for joganji and tateyama. Bundled PNGs in `assets/images/multi_sensor/`; scene picker updates preview via `ThumbnailPreview`.

## 5-Minute Demo Script

1. Open dashboard → Explorer mode, summary card shows coverage stats; SAR thumbnail panel shows bundled image (no network).
2. Select tateyama → footprint polygon appears on map.
3. Toggle Analyst → displacement legend, orbit filter.
4. Move timeline slider → thumbnail and chart update.
5. Switch industry template (e.g. ダム監視) → map/region/thumbnail refresh from template JSON.
6. Open Disaster archive → compare before/during/after phase thumbnails.
7. Open Multi-sensor → switch site and sensor; confirm optical vs SAR previews.
8. Navigate to Catalog → browse datasets; Architecture → system diagram; Procurement → mock cart.
