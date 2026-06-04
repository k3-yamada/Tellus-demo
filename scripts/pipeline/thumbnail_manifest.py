#!/usr/bin/env python3
"""Export thumbnail URL manifest for optional R2 mirroring."""

from __future__ import annotations

import json
import sys
from pathlib import Path

DEFAULT_PATH = Path(__file__).resolve().parent.parent.parent / "web_app" / "assets" / "data" / "infrastructure_data.json"
OUT_PATH = Path(__file__).resolve().parent.parent.parent / "web_app/assets/data/thumbnail_manifest.json"


def build_manifest(data: dict) -> dict:
    entries = []
    for region_id, region in (data.get("regions") or {}).items():
        for obs in region.get("observations") or []:
            url = obs.get("thumbnailUrl")
            if not url:
                continue
            entries.append({
                "regionId": region_id,
                "dataId": obs.get("dataId"),
                "datasetId": obs.get("datasetId"),
                "thumbnailUrl": url,
            })
    return {"count": len(entries), "entries": entries}


def main() -> None:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PATH
    with path.open(encoding="utf-8") as f:
        data = json.load(f)
    manifest = build_manifest(data)
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUT_PATH.open("w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"Wrote {OUT_PATH} ({manifest['count']} thumbnails)")


if __name__ == "__main__":
    main()
