#!/usr/bin/env python3
"""TelluSAR job submission and polling (optional pipeline step)."""

from __future__ import annotations

import os
import sys
import time
from pathlib import Path
from typing import Any

import requests
from dotenv import load_dotenv

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
ENV_PATH = PROJECT_ROOT / ".env"

TELLUSAR_BASE = "https://www.tellusxdp.com/api/tellusar/v1"


def auth_headers(api_key: str) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }


def submit_job(
    session: requests.Session,
    headers: dict[str, str],
    *,
    data_ids: list[str],
    job_type: str = "insar",
) -> dict[str, Any]:
    url = f"{TELLUSAR_BASE}/jobs/"
    body = {"data_ids": data_ids, "job_type": job_type}
    resp = session.post(url, headers=headers, json=body, timeout=120)
    resp.raise_for_status()
    return resp.json()


def poll_job(
    session: requests.Session,
    headers: dict[str, str],
    job_id: str,
    *,
    max_wait: int = 600,
    interval: int = 15,
) -> dict[str, Any]:
    url = f"{TELLUSAR_BASE}/jobs/{job_id}/"
    elapsed = 0
    while elapsed < max_wait:
        resp = session.get(url, headers=headers, timeout=60)
        resp.raise_for_status()
        data = resp.json()
        status = data.get("status") or data.get("state")
        if status in ("completed", "failed", "error"):
            return data
        time.sleep(interval)
        elapsed += interval
    raise TimeoutError(f"Job {job_id} did not complete within {max_wait}s")


def main() -> None:
    load_dotenv(ENV_PATH)
    api_key = os.getenv("TELLUS_API_KEY", "").strip()
    if not api_key:
        print("Error: TELLUS_API_KEY not set", file=sys.stderr)
        sys.exit(1)

    if len(sys.argv) < 3:
        print("Usage: tellusar_jobs.py <data_id_1> <data_id_2> [...]", file=sys.stderr)
        sys.exit(1)

    data_ids = sys.argv[1:]
    session = requests.Session()
    headers = auth_headers(api_key)

    print(f"Submitting TelluSAR job for {len(data_ids)} scenes...")
    job = submit_job(session, headers, data_ids=data_ids)
    job_id = job.get("id") or job.get("job_id")
    print(f"Job submitted: {job_id}")

    if job_id:
        result = poll_job(session, headers, job_id)
        print(f"Job finished: {result.get('status')}")


if __name__ == "__main__":
    main()
