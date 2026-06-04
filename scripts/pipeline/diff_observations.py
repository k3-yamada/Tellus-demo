"""Compare two infrastructure JSON snapshots and report new observation IDs."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def observation_ids(data: dict[str, Any]) -> dict[str, set[str]]:
    result: dict[str, set[str]] = {}
    for region_id, region in (data.get("regions") or {}).items():
        ids: set[str] = set()
        for obs in region.get("observations") or []:
            data_id = obs.get("dataId")
            if data_id:
                ids.add(data_id)
        result[region_id] = ids
    return result


def diff_observations(before: dict[str, Any], after: dict[str, Any]) -> dict[str, Any]:
    before_ids = observation_ids(before)
    after_ids = observation_ids(after)
    per_region: dict[str, int] = {}
    total_new = 0
    all_regions = set(before_ids) | set(after_ids)
    for region_id in sorted(all_regions):
        new_count = len(after_ids.get(region_id, set()) - before_ids.get(region_id, set()))
        per_region[region_id] = new_count
        total_new += new_count
    return {
        "totalNew": total_new,
        "perRegion": per_region,
        "beforeTotal": sum(len(v) for v in before_ids.values()),
        "afterTotal": sum(len(v) for v in after_ids.values()),
    }


def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def summarize_quality(data: dict[str, Any]) -> dict[str, Any]:
    qr = data.get("qualityReport") or {}
    meta = data.get("meta") or {}
    return {
        "generatedAt": meta.get("generatedAt"),
        "overallScore": qr.get("overallScore"),
        "totalObservations": qr.get("totalObservations"),
        "regionsWithThumbnails": qr.get("regionsWithThumbnails"),
        "sarDatasetCount": meta.get("sarDatasetCount"),
    }


def main() -> None:
    import sys

    if len(sys.argv) < 3:
        print("Usage: diff_observations.py <before.json> <after.json>", file=sys.stderr)
        raise SystemExit(1)
    before_path = Path(sys.argv[1])
    after_path = Path(sys.argv[2])
    before = load_json(before_path)
    after = load_json(after_path)
    diff = diff_observations(before, after)
    summary = summarize_quality(after)
    print(json.dumps({"diff": diff, "summary": summary}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
