"""Shared Tellus Traveler HTTP client."""

from __future__ import annotations

import sys
import time
from typing import Any

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

API_BASE = "https://www.tellusxdp.com/api/traveler/v1"
DATASETS_URL = f"{API_BASE}/datasets/"
DATA_SEARCH_URL = f"{API_BASE}/data-search/"


def build_session() -> requests.Session:
    retry = Retry(
        total=5,
        connect=5,
        read=5,
        backoff_factor=1.0,
        status_forcelist=(503,),
        allowed_methods=("GET", "POST"),
        raise_on_status=False,
    )
    adapter = HTTPAdapter(max_retries=retry)
    session = requests.Session()
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    return session


def auth_headers(api_key: str) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }


def request_json(
    session: requests.Session,
    method: str,
    url: str,
    headers: dict[str, str],
    *,
    params: dict[str, Any] | None = None,
    json_body: dict[str, Any] | None = None,
    exit_on_error: bool = True,
) -> dict[str, Any]:
    """HTTP request with manual 503 retries beyond urllib3."""
    last_response: requests.Response | None = None
    for attempt in range(6):
        response = session.request(
            method,
            url,
            headers=headers,
            params=params,
            json=json_body,
            timeout=120,
        )
        last_response = response
        if response.status_code == 503 and attempt < 5:
            time.sleep(min(2 ** attempt, 30))
            continue
        break

    assert last_response is not None
    if last_response.status_code == 401:
        msg = "Error: Unauthorized (401). Check TELLUS_API_KEY in .env"
        if exit_on_error:
            print(msg, file=sys.stderr)
            sys.exit(1)
        raise PermissionError(msg)
    if last_response.status_code == 422:
        try:
            detail = last_response.json()
        except ValueError:
            detail = last_response.text
        msg = f"Error: Unprocessable request (422): {detail}"
        if exit_on_error:
            print(msg, file=sys.stderr)
            sys.exit(1)
        raise ValueError(msg)
    if not last_response.ok:
        msg = f"Error: HTTP {last_response.status_code} for {url}: {last_response.text[:500]}"
        if exit_on_error:
            print(msg, file=sys.stderr)
            sys.exit(1)
        raise requests.HTTPError(msg)
    return last_response.json()


def fetch_paginated(
    session: requests.Session,
    url: str,
    headers: dict[str, str],
) -> list[dict[str, Any]]:
    """Fetch all pages from a paginated GET endpoint."""
    results: list[dict[str, Any]] = []
    next_url: str | None = url
    while next_url:
        payload = request_json(session, "GET", next_url, headers)
        results.extend(payload.get("results", []))
        next_url = payload.get("next")
    return results
