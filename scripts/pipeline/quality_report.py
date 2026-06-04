"""Compute quality report and coverage-by-year from infrastructure JSON."""

from __future__ import annotations

from collections import defaultdict
from typing import Any


def compute_quality_score(obs: dict[str, Any]) -> float:
    """Heuristic quality score 0-1 from available metadata."""
    score = 0.0
    if obs.get("dataId"):
        score += 0.2
    if obs.get("acquisitionDate"):
        score += 0.2
    if obs.get("orbitDirection"):
        score += 0.15
    if obs.get("polarization"):
        score += 0.15
    if obs.get("relativeOrbit") is not None:
        score += 0.1
    if obs.get("offNadir") is not None:
        score += 0.1
    if obs.get("geometry"):
        score += 0.05
    if obs.get("thumbnailUrl"):
        score += 0.05
    return min(score, 1.0)


def build_coverage_by_year(data: dict[str, Any]) -> dict[str, dict[str, int]]:
    """Count observations per year per region."""
    coverage: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    regions = data.get("regions") or {}
    for region_id, region in regions.items():
        for obs in region.get("observations") or []:
            date = obs.get("acquisitionDate") or (obs.get("start_datetime") or "")[:10]
            if len(date) >= 4:
                year = date[:4]
                coverage[region_id][year] += 1
    return {k: dict(v) for k, v in coverage.items()}


def build_quality_report(data: dict[str, Any]) -> dict[str, Any]:
    """Build aggregate quality report for v2 schema."""
    regions = data.get("regions") or {}
    total = 0
    with_geometry = 0
    with_thumbnails = 0
    scores: list[float] = []
    notes: list[str] = []

    for region_id, region in regions.items():
        obs_list = region.get("observations") or []
        total += len(obs_list)
        region_geo = 0
        region_thumb = 0
        for obs in obs_list:
            qs = obs.get("qualityScore")
            if qs is None:
                qs = compute_quality_score(obs)
                obs["qualityScore"] = qs
            scores.append(qs)
            if obs.get("geometry"):
                with_geometry += 1
                region_geo += 1
            if obs.get("thumbnailUrl"):
                with_thumbnails += 1
                region_thumb += 1
        if obs_list and region_geo == 0:
            notes.append(f"{region_id}: no geometry on observations (run enrich or re-fetch)")

    overall = sum(scores) / len(scores) if scores else 0.0
    return {
        "overallScore": round(overall, 3),
        "totalObservations": total,
        "regionsWithGeometry": with_geometry,
        "regionsWithThumbnails": with_thumbnails,
        "notes": notes,
    }



def attach_datasets_catalog(data, catalog):
    counts = {}
    for region in (data.get("regions") or {}).values():
        for obs in region.get("observations") or []:
            ds_id = obs.get("datasetId")
            if ds_id:
                counts[ds_id] = counts.get(ds_id, 0) + 1
    for entry in catalog:
        entry["observationCount"] = counts.get(entry.get("id"), 0)
    meta = data.setdefault("meta", {})
    meta["datasetsCatalog"] = catalog
    meta["tellusPortalUrl"] = "https://www.tellusxdp.com/"


def _attach_tellusar_pair(data: dict[str, Any]) -> None:
    try:
        from select_tellusar_pair import suggest_pair
        pair = suggest_pair(data)
        if pair:
            data.setdefault("meta", {})["tellusarSuggestedPair"] = pair
    except Exception:
        pass

def enrich_v2_fields(data: dict[str, Any]) -> dict[str, Any]:
    """Add schemaVersion, qualityReport, coverageByYear to existing data."""
    data["schemaVersion"] = 2
    data["qualityReport"] = build_quality_report(data)
    _attach_tellusar_pair(data)
    data["coverageByYear"] = build_coverage_by_year(data)

    meta = data.setdefault("meta", {})
    if "displacementDemo" not in meta:
        meta["displacementDemo"] = _default_displacement_demo()

    return data


def _default_displacement_demo() -> dict[str, Any]:
    """Precomputed displacement demo for tateyama Analyst mode."""
    return {
        "regionId": "tateyama",
        "unit": "mm",
        "baselineDate": "2016-01-01",
        "disclaimer": "Demo values only — not real TelluSAR analysis output",
        "values": [
            {"date": "2016-06-01", "displacementMm": -2.1},
            {"date": "2017-06-01", "displacementMm": -3.4},
            {"date": "2018-06-01", "displacementMm": -1.8},
            {"date": "2019-06-01", "displacementMm": -5.2},
            {"date": "2020-06-01", "displacementMm": -4.0},
            {"date": "2021-06-01", "displacementMm": -6.7},
            {"date": "2022-06-01", "displacementMm": -8.1},
            {"date": "2023-06-01", "displacementMm": -7.5},
            {"date": "2024-06-01", "displacementMm": -9.3},
            {"date": "2025-06-01", "displacementMm": -10.2},
        ],
    }
