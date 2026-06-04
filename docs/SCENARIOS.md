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
| `longTerm` | 長期トレンド — 全期間 | joganji |

## Displacement Demo

`meta.displacementDemo` in v2 JSON provides precomputed mm displacement values for tateyama region. This is **not** real TelluSAR output — it demonstrates Analyst mode UI only.

## Procurement Demo

When `DEMO_MODE=true`, the procurement page simulates cart and order flows without calling real Tellus billing APIs.

## 5-Minute Demo Script

1. Open dashboard → Explorer mode, summary card shows coverage stats.
2. Select tateyama → footprint polygon appears on map.
3. Toggle Analyst → displacement legend, orbit filter.
4. Move timeline slider → thumbnail and chart update.
5. Navigate to Catalog → browse datasets; Architecture → system diagram; Procurement → mock cart.
