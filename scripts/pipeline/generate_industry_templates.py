"""業界別テンプレ JSON 生成器。

5 種類のインフラ (ダム/橋梁/空港/新幹線高架/港湾) に対して、
infrastructure_data.v2.json と同じスキーマの "縮小版" テンプレを生成する。

観測 ID は決定論的に生成する (UUID v5 風)。Tellus dataset ID は本物。
これらのテンプレは「同じ仕組みで別案件にも適用できる」訴求デモ用で、
個々の観測値そのものは合成データ (synthesized) であることを明示する。
"""

from __future__ import annotations

import hashlib
import json
import math
import random
from datetime import datetime, timedelta, timezone
from pathlib import Path

from demo_png import make_sar_pixels, write_gray_png

ROOT = Path(__file__).resolve().parent.parent.parent
OUT_DIR = ROOT / "web_app" / "assets" / "data" / "templates"
THUMB_BASE = ROOT / "web_app" / "assets" / "images" / "templates"

DATASET_COARSE = {
    "b0e16dea-6544-4422-926f-ad3ec9a3fcbd",  # PALSAR-2 ScanSAR
}

# 本物の Tellus SAR dataset ID (PALSAR-2 / ALOS-2 系)。
# main の infrastructure_data.json から流用。
SAR_DATASETS = [
    {
        "id": "1a41a4b1-4594-431f-95fb-82f9bdc35d6b",
        "name": "PALSAR-2 L2.1 GeoTIFF",
        "desc": "L-band SAR, 3m GSD",
    },
    {
        "id": "b0e16dea-6544-4422-926f-ad3ec9a3fcbd",
        "name": "PALSAR-2 ScanSAR",
        "desc": "L-band wide-swath SAR, 25m",
    },
    {
        "id": "57233372-b507-4611-9c1f-bfd973a2fce6",
        "name": "ALOS-2 Spotlight",
        "desc": "L-band SAR, 1m GSD",
    },
]


def make_data_id(seed: str) -> str:
    """seed から UUID v5 風の決定論的 ID を生成。"""
    h = hashlib.sha1(seed.encode()).hexdigest()
    return f"{h[0:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:32]}"


def bbox_polygon(lat: float, lon: float, half_km: float = 5.0) -> list[list[float]]:
    """中心 (lat, lon) を囲む矩形 BBOX を GeoJSON Polygon の coords 形式で返す。"""
    dlat = half_km / 111.0
    dlon = half_km / (111.0 * math.cos(math.radians(lat)))
    return [[
        [lon - dlon, lat - dlat],
        [lon + dlon, lat - dlat],
        [lon + dlon, lat + dlat],
        [lon - dlon, lat + dlat],
        [lon - dlon, lat - dlat],
    ]]


def thumbnail_asset_path(template_id: str, data_id: str) -> str:
    return f"assets/images/templates/{template_id}/{data_id}.png"


def write_observation_thumbnail(template_id: str, data_id: str, dataset_id: str) -> str:
    rel = thumbnail_asset_path(template_id, data_id)
    out = THUMB_BASE / template_id / f"{data_id}.png"
    coarse = dataset_id in DATASET_COARSE
    write_gray_png(
        out,
        320,
        200,
        make_sar_pixels(f"{template_id}:{data_id}", coarse=coarse),
    )
    return rel


def synth_observations(
    template_id: str,
    region_id: str,
    lat: float,
    lon: float,
    start_year: int,
    count: int,
    base_index: float,
) -> list[dict]:
    """region に紐づく observations を決定論的に生成。"""
    rnd = random.Random(f"{region_id}-{start_year}-{count}")
    observations = []
    for i in range(count):
        ds = SAR_DATASETS[i % len(SAR_DATASETS)]
        day_offset = int(i * (365 * 8 / max(count - 1, 1)))  # 8 年間に分散
        date = datetime(start_year, 1, 15, tzinfo=timezone.utc) + timedelta(days=day_offset)
        iso = date.isoformat().replace("+00:00", "Z")
        seed = f"{region_id}-{i}-{ds['id']}"
        data_id = make_data_id(seed)
        observations.append({
            "dataId": data_id,
            "datasetId": ds["id"],
            "acquisitionDate": iso[:10],
            "start_datetime": iso,
            "orbitDirection": "ascending" if i % 2 == 0 else "descending",
            "polarization": "HH" if i % 3 == 0 else "HH+HV",
            "relativeOrbit": 100 + (i * 17) % 200,
            "offNadir": round(28.0 + rnd.uniform(-5, 8), 2),
            "monitoringIndex": round(base_index + rnd.uniform(-0.2, 0.2), 3),
            "geometry": {"type": "Polygon", "coordinates": bbox_polygon(lat, lon, 8.0)},
            "thumbnailUrl": write_observation_thumbnail(template_id, data_id, ds["id"]),
            "qualityScore": round(rnd.uniform(0.55, 0.92), 3),
        })
    return observations


def build_template(
    template_id: str,
    industry: str,
    icon: str,
    pitch: str,
    region_id: str,
    region_name: str,
    region_type: str,
    lat: float,
    lon: float,
    start_year: int,
    obs_count: int,
    base_index: float,
) -> dict:
    """1 テンプレ分の JSON dict を組み立てる。"""
    observations = synth_observations(
        template_id, region_id, lat, lon, start_year, obs_count, base_index
    )
    coverage: dict[str, dict[str, int]] = {region_id: {}}
    for obs in observations:
        year = obs["acquisitionDate"][:4]
        coverage[region_id][year] = coverage[region_id].get(year, 0) + 1

    return {
        "schemaVersion": 2,
        "meta": {
            "generatedAt": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "apiBase": "https://www.tellusxdp.com/api/traveler/v1",
            "templateId": template_id,
            "industry": industry,
            "industryIcon": icon,
            "pitch": pitch,
            "datasetsCatalog": [
                {"id": d["id"], "name": d["name"], "description": d["desc"], "observationCount": 0}
                for d in SAR_DATASETS
            ],
            "tellusPortalUrl": "https://www.tellusxdp.com/",
            "disclaimer": (
                "本テンプレの観測値は合成データです (synthesized)。"
                "Tellus dataset ID は実在しますが、個別シーンメタは "
                "本デモのために決定論的に生成しています。"
            ),
        },
        "qualityReport": {
            "overallScore": 0.78,
            "totalObservations": obs_count,
            "regionsWithGeometry": 1,
            "regionsWithThumbnails": 1,
            "notes": [
                f"{industry} 監視テンプレート (合成データ)",
                f"対象期間: {start_year}-01 〜 {start_year + 8}-01",
                "サムネイルはバンドル済み合成 PNG (bundled_demo_png)",
                "実運用ではこのスキーマに本物の Tellus 取得結果を流し込む",
            ],
        },
        "coverageByYear": coverage,
        "regions": {
            region_id: {
                "id": region_id,
                "name": region_name,
                "type": region_type,
                "infrastructureType": region_type,
                "lat": lat,
                "lon": lon,
                "description": pitch,
                "observationCount": obs_count,
                "observations": observations,
            }
        },
        "timeline": [
            {
                "regionId": region_id,
                "dataId": obs["dataId"],
                "acquisitionDate": obs["acquisitionDate"],
                "monitoringIndex": obs["monitoringIndex"],
            }
            for obs in observations
        ],
    }


TEMPLATES = [
    {
        "template_id": "dam",
        "industry": "ダム監視",
        "icon": "🏔",
        "pitch": "貯水池周辺の地盤変位と斜面状態を SAR で継続観測",
        "region_id": "kurobe_dam",
        "region_name": "黒部ダム周辺",
        "region_type": "dam",
        "lat": 36.5662,
        "lon": 137.6695,
        "start_year": 2017,
        "obs_count": 14,
        "base_index": 0.32,
    },
    {
        "template_id": "bridge",
        "industry": "橋梁監視",
        "icon": "🌉",
        "pitch": "長大橋・橋脚周辺の沈下と海岸侵食モニタリング",
        "region_id": "akashi_bridge",
        "region_name": "明石海峡大橋周辺",
        "region_type": "bridge",
        "lat": 34.6160,
        "lon": 135.0214,
        "start_year": 2017,
        "obs_count": 12,
        "base_index": 0.45,
    },
    {
        "template_id": "airport",
        "industry": "空港監視",
        "icon": "🛬",
        "pitch": "埋立地空港の地盤沈下を mm 単位で長期トレンド分析",
        "region_id": "kix_airport",
        "region_name": "関西国際空港",
        "region_type": "airport",
        "lat": 34.4347,
        "lon": 135.2444,
        "start_year": 2016,
        "obs_count": 16,
        "base_index": 0.58,
    },
    {
        "template_id": "shinkansen",
        "industry": "新幹線高架監視",
        "icon": "🚄",
        "pitch": "高架橋梁・盛土の連続観測で保線業務を支援",
        "region_id": "tokai_kakehashi",
        "region_name": "東海道新幹線 名古屋〜京都区間",
        "region_type": "rail_viaduct",
        "lat": 35.0832,
        "lon": 136.5028,
        "start_year": 2018,
        "obs_count": 10,
        "base_index": 0.41,
    },
    {
        "template_id": "port",
        "industry": "港湾監視",
        "icon": "⚓",
        "pitch": "港湾施設・防波堤・コンテナヤードの変位検出",
        "region_id": "yokohama_port",
        "region_name": "横浜港",
        "region_type": "port",
        "lat": 35.4437,
        "lon": 139.6380,
        "start_year": 2017,
        "obs_count": 13,
        "base_index": 0.50,
    },
]


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    index = []
    for spec in TEMPLATES:
        template = build_template(**spec)
        path = OUT_DIR / f"{spec['template_id']}.json"
        with path.open("w", encoding="utf-8") as f:
            json.dump(template, f, ensure_ascii=False, indent=2)
        index.append({
            "id": spec["template_id"],
            "industry": spec["industry"],
            "icon": spec["icon"],
            "pitch": spec["pitch"],
            "region_name": spec["region_name"],
            "lat": spec["lat"],
            "lon": spec["lon"],
            "asset_path": f"assets/data/templates/{spec['template_id']}.json",
        })
        print(f"wrote {path}")

    index_path = OUT_DIR / "index.json"
    with index_path.open("w", encoding="utf-8") as f:
        json.dump({"templates": index}, f, ensure_ascii=False, indent=2)
    print(f"wrote {index_path}")


if __name__ == "__main__":
    main()
