#!/usr/bin/env python3
"""Merge TelluSAR job output JSON into meta.displacementDemo (optional post-processing)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

DEFAULT_DATA = Path(__file__).resolve().parent.parent.parent / "web_app" / "assets" / "data" / "infrastructure_data.json"


def merge_result(data: dict, job_result: dict) -> None:
    values = []
    for item in job_result.get("values") or job_result.get("displacements") or []:
        if isinstance(item, dict) and "date" in item:
            values.append({
                "date": item["date"],
                "displacementMm": float(item.get("displacementMm") or item.get("value") or 0),
            })
    if not values:
        return
    meta = data.setdefault("meta", {})
    meta["displacementDemo"] = {
        "regionId": job_result.get("regionId") or "tateyama",
        "unit": job_result.get("unit") or "mm",
        "baselineDate": job_result.get("baselineDate") or values[0]["date"],
        "disclaimer": "Merged from TelluSAR job output — verify before production use",
        "values": values,
    }
    meta["tellusarLastJob"] = {
        "jobId": job_result.get("jobId") or job_result.get("id"),
        "status": job_result.get("status"),
    }


def main() -> None:
    if len(sys.argv) < 3:
        print("Usage: merge_tellusar_result.py <infrastructure.json> <job_result.json>", file=sys.stderr)
        sys.exit(1)
    data_path = Path(sys.argv[1])
    result_path = Path(sys.argv[2])
    with data_path.open(encoding="utf-8") as f:
        data = json.load(f)
    with result_path.open(encoding="utf-8") as f:
        job_result = json.load(f)
    merge_result(data, job_result)
    with data_path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"Merged TelluSAR result into {data_path}")


if __name__ == "__main__":
    main()
