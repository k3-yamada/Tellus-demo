#!/usr/bin/env python3
"""Enrich observations with scene detail, thumbnails, and geometry."""

from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path

from dotenv import load_dotenv

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
sys.path.insert(0, str(SCRIPT_DIR.parent))

from tellus_client import API_BASE, auth_headers, build_session, request_json

DEFAULT_PATH = PROJECT_ROOT / "web_app" / "assets" / "data" / "infrastructure_data.json"
ENV_PATH = PROJECT_ROOT / ".env"
RATE_LIMIT_SLEEP = 0.3


def fetch_scene_detail(session, headers, data_id: str) -> dict:
    url = f"{API_BASE}/data/{data_id}/"
    return request_json(session, "GET", url, headers, exit_on_error=False)


def fetch_thumbnail_url(session, headers, data_id: str) -> str | None:
    url = f"{API_BASE}/data/{data_id}/thumbnails/"
    try:
        payload = request_json(session, "GET", url, headers, exit_on_error=False)
        results = payload.get("results") or payload.get("thumbnails") or []
        if results and isinstance(results, list):
            first = results[0]
            if isinstance(first, dict):
                return first.get("url") or first.get("thumbnail_url")
        if isinstance(payload, dict) and payload.get("url"):
            return payload["url"]
    except (ValueError, PermissionError, Exception):
        pass
    return None


def enrich_observation(session, headers, obs: dict) -> dict:
    data_id = obs.get("dataId")
    if not data_id:
        return obs

    if not obs.get("geometry"):
        try:
            detail = fetch_scene_detail(session, headers, data_id)
            geom = detail.get("geometry")
            if geom:
                obs["geometry"] = geom
        except Exception:
            pass
        time.sleep(RATE_LIMIT_SLEEP)

    if not obs.get("thumbnailUrl"):
        thumb = fetch_thumbnail_url(session, headers, data_id)
        if thumb:
            obs["thumbnailUrl"] = thumb
        time.sleep(RATE_LIMIT_SLEEP)

    return obs


def enrich_file(path: Path, *, limit: int | None = None) -> None:
    load_dotenv(ENV_PATH)
    api_key = os.getenv("TELLUS_API_KEY", "").strip()
    if not api_key:
        print("Error: TELLUS_API_KEY not set", file=sys.stderr)
        sys.exit(1)

    with path.open(encoding="utf-8") as f:
        data = json.load(f)

    session = build_session()
    headers = auth_headers(api_key)
    count = 0

    for region in (data.get("regions") or {}).values():
        observations = region.get("observations") or []
        for i, obs in enumerate(observations):
            if limit is not None and count >= limit:
                break
            if obs.get("geometry") and obs.get("thumbnailUrl"):
                continue
            enrich_observation(session, headers, obs)
            count += 1
            if count % 10 == 0:
                print(f"  enriched {count} observations...")

    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"Enriched {count} observations in {path}")


def main() -> None:
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PATH
    limit = int(sys.argv[2]) if len(sys.argv) > 2 else None
    enrich_file(target, limit=limit)


if __name__ == "__main__":
    main()
