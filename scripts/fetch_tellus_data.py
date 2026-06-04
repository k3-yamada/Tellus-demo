#!/usr/bin/env python3
"""Fetch Tellus Traveler SAR observations for infrastructure monitoring regions."""

from __future__ import annotations

import json
import shutil
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from dotenv import load_dotenv

from tellus_client import (
    API_BASE,
    DATA_SEARCH_URL,
    auth_headers,
    build_session,
    fetch_paginated,
    request_json,
)

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
sys.path.insert(0, str(SCRIPT_DIR / "pipeline"))

from quality_report import attach_datasets_catalog, enrich_v2_fields

ENV_PATH = PROJECT_ROOT / ".env"
OUTPUT_PATH = PROJECT_ROOT / "web_app" / "assets" / "data" / "infrastructure_data.json"

SAR_KEYWORDS = re.compile(r"PALSAR|SAR|SENTINEL|S1|ALOS", re.IGNORECASE)
MAX_OBSERVATIONS_PER_REGION = 500
BBOX_DELTA_DEG = 0.08
PAGE_SIZE = 100
START_DATETIME_GTE = "2016-01-01T00:00:00Z"

REGIONS = [
    {
        "id": "joganji",
        "name": "常願寺川流域（佐々堤付近）",
        "lat": 36.598,
        "lon": 137.340,
        "infrastructureType": "embankment",
        "description": "富山市大山町馬瀬口・佐々堤周辺の河川堤防",
    },
    {
        "id": "tateyama",
        "name": "立山室堂（斜面）",
        "lat": 36.577,
        "lon": 137.596,
        "infrastructureType": "slope",
        "description": "立山カルデラ・室堂平周辺の火山斜面",
    },
]


def fetch_sar_catalog(session, headers) -> tuple[list[str], list[dict[str, Any]]]:
    items = fetch_paginated(session, f"{API_BASE}/datasets/", headers)
    dataset_ids: list[str] = []
    catalog: list[dict[str, Any]] = []
    for item in items:
        name = item.get("name") or ""
        description = item.get("description") or ""
        tags = " ".join(item.get("tags") or [])
        blob = f"{name} {description} {tags}"
        if SAR_KEYWORDS.search(blob):
            ds_id = item["id"]
            dataset_ids.append(ds_id)
            catalog.append({
                "id": ds_id,
                "name": name or ds_id,
                "description": (description or "")[:240],
                "observationCount": 0,
            })
    return dataset_ids, catalog


def bbox_polygon(lon: float, lat: float, delta: float = BBOX_DELTA_DEG) -> dict[str, Any]:
    ring = [
        [lon - delta, lat - delta],
        [lon + delta, lat - delta],
        [lon + delta, lat + delta],
        [lon - delta, lat + delta],
        [lon - delta, lat - delta],
    ]
    return {"type": "Polygon", "coordinates": [ring]}


def clamp(value: float, low: float, high: float) -> float:
    return max(low, min(high, value))


def parse_observation(feature: dict[str, Any]) -> dict[str, Any]:
    props = feature.get("properties") or {}
    start_dt = props.get("start_datetime") or ""
    acquisition_date = start_dt[:10] if start_dt else None

    off_nadir_raw = props.get("view:off_nadir")
    off_nadir = float(off_nadir_raw) if off_nadir_raw is not None else None
    monitoring_index = None
    if off_nadir is not None:
        monitoring_index = clamp(off_nadir / 60.0, 0.0, 1.0)

    pol = props.get("sar:polarizations")
    if isinstance(pol, list):
        polarization = "+".join(str(p) for p in pol)
    else:
        polarization = pol

    obs: dict[str, Any] = {
        "dataId": feature.get("id"),
        "datasetId": feature.get("dataset_id"),
        "acquisitionDate": acquisition_date,
        "start_datetime": start_dt,
        "orbitDirection": props.get("sar:observation_direction"),
        "polarization": polarization,
        "relativeOrbit": props.get("sat:relative_orbit"),
        "offNadir": off_nadir,
        "monitoringIndex": monitoring_index,
    }

    geometry = feature.get("geometry")
    if geometry:
        obs["geometry"] = geometry

    return obs


def is_sar_feature(feature: dict[str, Any], sar_dataset_ids: set[str]) -> bool:
    if feature.get("dataset_id") in sar_dataset_ids:
        return True
    props = feature.get("properties") or {}
    return any(str(k).startswith("sar:") for k in props)


def geometry_overlaps_region(
    feature: dict[str, Any], lat: float, lon: float, delta: float = BBOX_DELTA_DEG
) -> bool:
    geometry = feature.get("geometry") or {}
    ring = geometry.get("coordinates", [[]])[0]
    if not ring:
        return False
    min_lat = min(point[1] for point in ring)
    max_lat = max(point[1] for point in ring)
    min_lon = min(point[0] for point in ring)
    max_lon = max(point[0] for point in ring)
    return not (
        max_lat < lat - delta
        or min_lat > lat + delta
        or max_lon < lon - delta
        or min_lon > lon + delta
    )


def fetch_region_observations(
    session,
    headers,
    region: dict[str, Any],
    sar_dataset_ids: list[str],
    end_datetime_lte: str,
) -> list[dict[str, Any]]:
    seen: set[str] = set()
    observations: list[dict[str, Any]] = []
    cursor: str | None = None
    lat = region["lat"]
    lon = region["lon"]

    while len(observations) < MAX_OBSERVATIONS_PER_REGION:
        body: dict[str, Any] = {
            "datasets": sar_dataset_ids,
            "intersects": bbox_polygon(lon, lat),
            "query": {
                "start_datetime": {"gte": START_DATETIME_GTE},
                "end_datetime": {"lte": end_datetime_lte},
            },
            "sortby": [{"field": "properties.start_datetime", "direction": "asc"}],
            "paginate": {"size": PAGE_SIZE, "cursor": cursor},
        }
        payload = request_json(session, "POST", DATA_SEARCH_URL, headers, json_body=body)
        features = payload.get("features") or []
        if not features:
            break

        for feature in features:
            if not is_sar_feature(feature, set(sar_dataset_ids)):
                continue
            if not geometry_overlaps_region(feature, lat, lon):
                continue
            data_id = feature.get("id")
            if not data_id or data_id in seen:
                continue
            seen.add(data_id)
            observations.append(parse_observation(feature))
            if len(observations) >= MAX_OBSERVATIONS_PER_REGION:
                break

        search_cond = (payload.get("meta") or {}).get("search-condition") or {}
        paginate = search_cond.get("paginate") or {}
        cursor = paginate.get("cursor")
        if not cursor:
            break

    observations.sort(key=lambda o: (o.get("start_datetime") or "", o.get("dataId") or ""))
    return observations


def build_timeline(regions_output: dict[str, Any]) -> list[dict[str, Any]]:
    timeline: list[dict[str, Any]] = []
    for region_id, region_data in regions_output.items():
        for obs in region_data.get("observations", []):
            timeline.append(
                {
                    "regionId": region_id,
                    "dataId": obs.get("dataId"),
                    "acquisitionDate": obs.get("acquisitionDate"),
                    "monitoringIndex": obs.get("monitoringIndex"),
                    "relativeOrbit": obs.get("relativeOrbit"),
                    "orbitDirection": obs.get("orbitDirection"),
                }
            )
    timeline.sort(
        key=lambda e: (e.get("acquisitionDate") or "", e.get("regionId") or "", e.get("dataId") or "")
    )
    return timeline


def main() -> None:
    import os

    load_dotenv(ENV_PATH)
    api_key = os.getenv("TELLUS_API_KEY", "").strip()
    if not api_key:
        print("Error: TELLUS_API_KEY is not set in ../.env", file=sys.stderr)
        sys.exit(1)

    end_datetime_lte = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    headers = auth_headers(api_key)

    session = build_session()
    print("Fetching SAR dataset list...")
    sar_dataset_ids_list, sar_catalog = fetch_sar_catalog(session, headers)
    sar_dataset_ids = set(sar_dataset_ids_list)
    print(f"Matched {len(sar_dataset_ids)} SAR-related datasets")

    regions_output: dict[str, Any] = {}
    for region in REGIONS:
        print(f"Searching region {region['id']} ({region['name']})...")
        observations = fetch_region_observations(
            session, headers, region, sar_dataset_ids_list, end_datetime_lte
        )
        regions_output[region["id"]] = {
            **region,
            "observationCount": len(observations),
            "observations": observations,
        }
        print(f"  -> {len(observations)} observations")

    output: dict[str, Any] = {
        "meta": {
            "generatedAt": datetime.now(timezone.utc).isoformat(),
            "apiBase": API_BASE,
            "startDatetimeGte": START_DATETIME_GTE,
            "endDatetimeLte": end_datetime_lte,
            "sarDatasetCount": len(sar_dataset_ids),
            "sarDatasetIds": sar_dataset_ids_list,
            "maxObservationsPerRegion": MAX_OBSERVATIONS_PER_REGION,
        },
        "regions": regions_output,
        "timeline": build_timeline(regions_output),
    }

    attach_datasets_catalog(output, sar_catalog)
    enrich_v2_fields(output)

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    if OUTPUT_PATH.exists():
        shutil.copy2(OUTPUT_PATH, OUTPUT_PATH.with_suffix(".previous.json"))
    with OUTPUT_PATH.open("w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"Wrote {OUTPUT_PATH} (schemaVersion=2)")
    for region_id, data in regions_output.items():
        print(f"Summary {region_id}: observationCount={data['observationCount']}")


if __name__ == "__main__":
    main()
