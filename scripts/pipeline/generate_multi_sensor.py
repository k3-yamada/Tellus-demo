"""マルチセンサー (SAR + 光学) 比較データ生成器。

同一地点について、Tellus で取得できる複数センサーのシーンメタを
横並びで提示する。Tellus dataset ID は実在のもの。シーン ID は合成。
"""

from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

from demo_png import make_optical_pixels, make_sar_pixels, write_gray_png, write_rgb_png

OUT_PATH = (
    Path(__file__).resolve().parent.parent.parent
    / "web_app"
    / "assets"
    / "data"
    / "multi_sensor.json"
)

THUMB_DIR = (
    Path(__file__).resolve().parent.parent.parent
    / "web_app"
    / "assets"
    / "images"
    / "multi_sensor"
)


def scene_id(seed: str) -> str:
    h = hashlib.sha1(seed.encode()).hexdigest()
    return f"{h[0:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:32]}"


SITES = [
    {
        "id": "tateyama_slope",
        "name": "立山室堂斜面",
        "lat": 36.577,
        "lon": 137.596,
        "context": "本デモのメイン斜面監視地点。SAR と光学の特性比較に最適。",
    },
    {
        "id": "joganji_river",
        "name": "常願寺川流域 (佐々堤)",
        "lat": 36.598,
        "lon": 137.340,
        "context": "堤防の長期トレンドと豪雨後変化の比較。",
    },
]

SENSORS = [
    {
        "id": "palsar2_l21",
        "name": "PALSAR-2 L2.1 GeoTIFF",
        "datasetId": "1a41a4b1-4594-431f-95fb-82f9bdc35d6b",
        "modality": "SAR",
        "band": "L-band",
        "gsd_m": 3.0,
        "strengths": ["雲・夜間貫通", "粗面検出", "干渉解析 (InSAR) 可能"],
        "weakness": "色情報なし",
    },
    {
        "id": "palsar2_scansar",
        "name": "PALSAR-2 ScanSAR",
        "datasetId": "b0e16dea-6544-4422-926f-ad3ec9a3fcbd",
        "modality": "SAR",
        "band": "L-band",
        "gsd_m": 25.0,
        "strengths": ["広域 (350km) を 1 シーンで把握", "災害直後の緊急観測向き"],
        "weakness": "詳細解析には不向き",
    },
    {
        "id": "asnaro1_optical",
        "name": "ASNARO-1 光学",
        "datasetId": "57233372-b507-4611-9c1f-bfd973a2fce6",
        "modality": "Optical",
        "band": "VNIR",
        "gsd_m": 0.5,
        "strengths": ["人間が直感的に判読できる", "高解像度の地物識別"],
        "weakness": "雲・夜間 NG",
    },
    {
        "id": "landsat8",
        "name": "Landsat-8 OLI",
        "datasetId": "8836ec9a-35b5-43c3-92be-263498061e91",
        "modality": "Optical",
        "band": "VNIR/SWIR",
        "gsd_m": 30.0,
        "strengths": ["NDVI など指数解析", "16 日ごとの定期観測"],
        "weakness": "解像度低 + 雲影響大",
    },
]


def write_scene_thumbnail(site_id: str, sensor_id: str) -> str:
    rel = f"assets/images/multi_sensor/{site_id}_{sensor_id}.png"
    out = THUMB_DIR / f"{site_id}_{sensor_id}.png"
    seed = f"{site_id}:{sensor_id}"
    if sensor_id in ("palsar2_l21", "palsar2_scansar"):
        write_gray_png(
            out,
            320,
            200,
            make_sar_pixels(seed, coarse=sensor_id == "palsar2_scansar"),
        )
    else:
        write_rgb_png(out, 320, 200, make_optical_pixels(seed))
    return rel


def synth_scene(
    site_id: str, sensor_id: str, year: int, month: int, day: int, orbit: str | None
) -> dict:
    iso = (
        datetime(year, month, day, 10, 0, 0, tzinfo=timezone.utc)
        .isoformat()
        .replace("+00:00", "Z")
    )
    return {
        "sensorId": sensor_id,
        "sceneId": scene_id(f"{site_id}-{sensor_id}-{iso}"),
        "acquisitionDate": iso[:10],
        "acquisitionDatetime": iso,
        "orbitDirection": orbit,
        "thumbnailUrl": write_scene_thumbnail(site_id, sensor_id),
    }


def build_scenes(site_id: str) -> list[dict]:
    return [
        synth_scene(site_id, "palsar2_l21", 2023, 5, 15, "ascending"),
        synth_scene(site_id, "palsar2_l21", 2024, 5, 12, "ascending"),
        synth_scene(site_id, "palsar2_scansar", 2023, 7, 8, "descending"),
        synth_scene(site_id, "asnaro1_optical", 2024, 4, 22, None),
        synth_scene(site_id, "landsat8", 2023, 9, 3, None),
        synth_scene(site_id, "landsat8", 2024, 9, 6, None),
    ]


def main() -> None:
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "schemaVersion": 1,
        "generatedAt": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "disclaimer": (
            "シーン ID と取得時刻は合成データ。Tellus dataset ID は実在のもの。"
            "サムネイルはデモ用合成 PNG。実運用では Tellus data-search の結果に差し替える。"
        ),
        "sensors": SENSORS,
        "sites": [{**site, "scenes": build_scenes(site["id"])} for site in SITES],
    }
    with OUT_PATH.open("w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    print(f"wrote {OUT_PATH}")


if __name__ == "__main__":
    main()
