#!/usr/bin/env python3
"""Refresh meta.datasetsCatalog from Tellus API without re-fetching observations."""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

from dotenv import load_dotenv

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
sys.path.insert(0, str(SCRIPT_DIR.parent))

from quality_report import attach_datasets_catalog, enrich_v2_fields
from tellus_client import API_BASE, auth_headers, build_session, fetch_paginated

SAR_KEYWORDS = re.compile(r"PALSAR|SAR|SENTINEL|S1|ALOS", re.IGNORECASE)
DEFAULT_PATH = PROJECT_ROOT / "web_app" / "assets" / "data" / "infrastructure_data.json"
ENV_PATH = PROJECT_ROOT / ".env"


def fetch_catalog(session, headers) -> list[dict]:
    items = fetch_paginated(session, f"{API_BASE}/datasets/", headers)
    catalog = []
    for item in items:
        name = item.get("name") or ""
        description = item.get("description") or ""
        tags = " ".join(item.get("tags") or [])
        if SAR_KEYWORDS.search(f"{name} {description} {tags}"):
            catalog.append(
                {
                    "id": item["id"],
                    "name": name or item["id"],
                    "description": (description or "")[:240],
                    "observationCount": 0,
                }
            )
    return catalog


def main() -> None:
    load_dotenv(ENV_PATH)
    api_key = os.getenv("TELLUS_API_KEY", "").strip()
    if not api_key:
        print("TELLUS_API_KEY required", file=sys.stderr)
        sys.exit(1)
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PATH
    with path.open(encoding="utf-8") as f:
        data = json.load(f)
    session = build_session()
    headers = auth_headers(api_key)
    catalog = fetch_catalog(session, headers)
    attach_datasets_catalog(data, catalog)
    enrich_v2_fields(data)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"Updated datasetsCatalog ({len(catalog)} entries) in {path}")


if __name__ == "__main__":
    main()
