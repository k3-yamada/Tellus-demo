#!/usr/bin/env python3
"""Pick two scenes from infrastructure JSON suitable for TelluSAR InSAR demo."""

from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

DEFAULT_PATH = Path(__file__).resolve().parent.parent.parent / "web_app" / "assets" / "data" / "infrastructure_data.json"


def suggest_pair(data: dict[str, Any], region_id: str = "tateyama") -> dict[str, Any] | None:
    region = (data.get("regions") or {}).get(region_id) or {}
    observations = region.get("observations") or []
    buckets: dict[tuple[str, str | None], list[dict]] = defaultdict(list)
    for obs in observations:
        orbit = obs.get("orbitDirection") or ""
        pol = obs.get("polarization") or ""
        if not obs.get("dataId") or not orbit:
            continue
        buckets[(orbit, pol)].append(obs)

    best: tuple[dict, dict] | None = None
    best_gap = -1
    for group in buckets.values():
        if len(group) < 2:
            continue
        sorted_obs = sorted(
            group,
            key=lambda o: o.get("start_datetime") or o.get("acquisitionDate") or "",
        )
        first, last = sorted_obs[0], sorted_obs[-1]
        gap = abs(
            (last.get("monitoringIndex") or 0) - (first.get("monitoringIndex") or 0)
        )
        if gap > best_gap:
            best_gap = gap
            best = (first, last)
    if not best:
        return None
    a, b = best
    return {
        "regionId": region_id,
        "dataIds": [a["dataId"], b["dataId"]],
        "orbitDirection": a.get("orbitDirection"),
        "polarization": a.get("polarization"),
        "acquisitionDates": [a.get("acquisitionDate"), b.get("acquisitionDate")],
        "note": "Suggested pair for TelluSAR CLI (same orbit/pol, wide time span)",
    }


def attach_suggested_pair(data: dict[str, Any]) -> dict[str, Any] | None:
    pair = suggest_pair(data)
    if pair:
        data.setdefault("meta", {})["tellusarSuggestedPair"] = pair
    return pair


def main() -> None:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PATH
    with path.open(encoding="utf-8") as f:
        data = json.load(f)
    pair = attach_suggested_pair(data)
    if not pair:
        print("No suitable pair found", file=sys.stderr)
        sys.exit(1)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(json.dumps(pair, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
