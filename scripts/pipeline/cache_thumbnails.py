#!/usr/bin/env python3
"""Tellus Traveler から実 SAR サムネイルを取得し、バンドル資産として保存する。

署名付き URL（enrich_scenes.py）は約1時間で失効するため、本スクリプトは
PNG を web_app/assets/images/ に永続化し、JSON の thumbnailUrl を
assets/images/... パスに差し替える。

対象:
  - infrastructure: infrastructure_data.json（実 dataId、推奨）
  - disaster: disaster_archive.json（合成 sceneId のため --bbox-search 推奨）
  - multi_sensor: multi_sensor.json（合成 sceneId、--bbox-search 推奨）
  - templates: templates/*.json（合成 dataId、--bbox-search 推奨）

API キーは .env の TELLUS_API_KEY のみ使用（ブラウザへは露出しない）。
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Callable, Iterator

import requests
from dotenv import load_dotenv

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
sys.path.insert(0, str(SCRIPT_DIR.parent))

from enrich_scenes import RATE_LIMIT_SLEEP, fetch_thumbnail_url  # noqa: E402
from tellus_client import DATA_SEARCH_URL, auth_headers, build_session, request_json  # noqa: E402

ENV_PATH = PROJECT_ROOT / ".env"
DEFAULT_INFRA = PROJECT_ROOT / "web_app" / "assets" / "data" / "infrastructure_data.json"

DATASET_SLUG = {
    "1a41a4b1-4594-431f-95fb-82f9bdc35d6b": "palsar2_l21",
    "b0e16dea-6544-4422-926f-ad3ec9a3fcbd": "palsar2_scansar",
    "45ff087d-be02-4788-bc4c-28cd947a1167": "palsar2_slc",
    "ab4cd6a5-4ac9-4656-a5b5-a782ea0885c7": "alpsmlc30",
    "57233372-b507-4611-9c1f-bfd973a2fce6": "alos2_spotlight",
}

BBOX_DELTA_DEG = 0.08


def disaster_phase_date_window(phase: str, acquisition_date: str) -> tuple[str, str]:
    """フェーズ別に Tellus 検索用の日付ウィンドウを返す（YYYY-MM-DD）。"""
    base = datetime.strptime(acquisition_date[:10], "%Y-%m-%d").date()
    if phase == "before":
        gte = (base - timedelta(days=30)).isoformat()
        lte = base.isoformat()
    elif phase == "during":
        gte = (base - timedelta(days=7)).isoformat()
        lte = (base + timedelta(days=7)).isoformat()
    else:
        gte = base.isoformat()
        lte = (base + timedelta(days=30)).isoformat()
    return gte, lte


def asset_out_path(asset_rel: str) -> Path:
    """assets/images/... → web_app/assets/images/..."""
    return PROJECT_ROOT / "web_app" / asset_rel


@dataclass
class CacheJob:
    data_id: str
    dataset_id: str
    asset_rel: str
    out_path: Path
    region_id: str | None = None
    lat: float | None = None
    lon: float | None = None
    acquisition_gte: str | None = None
    acquisition_lte: str | None = None
    resolved_data_id: str | None = field(default=None, repr=False)
    resolved_dataset_id: str | None = field(default=None, repr=False)


def bbox_polygon(lon: float, lat: float, delta: float = BBOX_DELTA_DEG) -> dict[str, Any]:
    ring = [
        [lon - delta, lat - delta],
        [lon + delta, lat - delta],
        [lon + delta, lat + delta],
        [lon - delta, lat + delta],
        [lon - delta, lat - delta],
    ]
    return {"type": "Polygon", "coordinates": [ring]}


def download_image(session: requests.Session, url: str, dest: Path) -> bool:
    try:
        response = session.get(url, timeout=120)
        if response.status_code != 200 or not response.content:
            return False
        content_type = (response.headers.get("Content-Type") or "").lower()
        if "image" not in content_type and not response.content[:8].startswith(
            b"\x89PNG\r\n\x1a\n"
        ):
            return False
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(response.content)
        return True
    except requests.RequestException:
        return False


def search_scene_near(
    session: requests.Session,
    headers: dict[str, str],
    *,
    dataset_id: str,
    lat: float,
    lon: float,
    acquisition_gte: str | None = None,
    acquisition_lte: str | None = None,
) -> tuple[str, str] | None:
    gte = acquisition_gte or "2016-01-01T00:00:00Z"
    lte = acquisition_lte or datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    if "T" not in gte:
        gte = f"{gte}T00:00:00Z"
    if "T" not in lte:
        lte = f"{lte}T23:59:59Z"

    body: dict[str, Any] = {
        "datasets": [dataset_id],
        "intersects": bbox_polygon(lon, lat),
        "query": {
            "start_datetime": {"gte": gte},
            "end_datetime": {"lte": lte},
        },
        "sortby": [{"field": "properties.start_datetime", "direction": "desc"}],
        "paginate": {"size": 10, "cursor": None},
    }

    try:
        payload = request_json(
            session, "POST", DATA_SEARCH_URL, headers, json_body=body, exit_on_error=False
        )
    except (ValueError, PermissionError, requests.HTTPError):
        return None

    for feature in payload.get("features") or []:
        data_id = feature.get("id")
        ds_id = feature.get("dataset_id") or dataset_id
        if data_id and ds_id:
            return data_id, ds_id
    return None


def cache_one(
    session: requests.Session,
    headers: dict[str, str],
    job: CacheJob,
    *,
    dry_run: bool,
    skip_existing: bool,
    use_bbox_search: bool,
) -> tuple[bool, str]:
    if skip_existing and job.out_path.is_file():
        return True, "skipped"

    data_id = job.data_id
    dataset_id = job.dataset_id

    if use_bbox_search and job.lat is not None and job.lon is not None:
        found = None
        date_windows: list[tuple[str | None, str | None]] = []
        if job.acquisition_gte and job.acquisition_lte:
            date_windows.append((job.acquisition_gte, job.acquisition_lte))
            # 狭いウィンドウでヒットしない場合に広げる
            try:
                g = datetime.strptime(job.acquisition_gte[:10], "%Y-%m-%d").date()
                l = datetime.strptime(job.acquisition_lte[:10], "%Y-%m-%d").date()
                mid = g + (l - g) / 2
                pad = max((l - g).days, 7)
                wide_g = (mid - timedelta(days=pad)).isoformat()
                wide_l = (mid + timedelta(days=pad)).isoformat()
                date_windows.append((wide_g, wide_l))
            except ValueError:
                pass
        date_windows.append((None, None))

        for gte, lte in date_windows:
            found = search_scene_near(
                session,
                headers,
                dataset_id=dataset_id,
                lat=job.lat,
                lon=job.lon,
                acquisition_gte=gte,
                acquisition_lte=lte,
            )
            time.sleep(RATE_LIMIT_SLEEP)
            if found:
                break
        if not found:
            return False, "bbox_search_miss"
        data_id, dataset_id = found
        job.resolved_data_id = data_id
        job.resolved_dataset_id = dataset_id

    thumb_url = fetch_thumbnail_url(session, headers, dataset_id, data_id)
    time.sleep(RATE_LIMIT_SLEEP)
    if not thumb_url:
        return False, "no_thumbnail_url"

    if dry_run:
        return True, "dry_run"

    if not download_image(session, thumb_url, job.out_path):
        return False, "download_failed"

    return True, "cached"


def infra_jobs_by_observation(
    data: dict[str, Any], *, limit: int | None
) -> list[CacheJob]:
    jobs: list[CacheJob] = []
    for region_id, region in (data.get("regions") or {}).items():
        for obs in region.get("observations") or []:
            if limit is not None and len(jobs) >= limit:
                return jobs
            data_id = obs.get("dataId")
            dataset_id = obs.get("datasetId")
            if not data_id or not dataset_id:
                continue
            rel = f"assets/images/sar/cached/{region_id}/{data_id}.png"
            out = asset_out_path(rel)
            jobs.append(
                CacheJob(data_id, dataset_id, rel, out, region_id=region_id)
            )
    return jobs


def infra_jobs_by_dataset(data: dict[str, Any]) -> list[CacheJob]:
    seen: set[tuple[str, str]] = set()
    jobs: list[CacheJob] = []
    for region_id, region in (data.get("regions") or {}).items():
        for obs in region.get("observations") or []:
            dataset_id = obs.get("datasetId")
            data_id = obs.get("dataId")
            if not dataset_id or not data_id:
                continue
            key = (region_id, dataset_id)
            if key in seen:
                continue
            seen.add(key)
            slug = DATASET_SLUG.get(dataset_id, "generic")
            rel = f"assets/images/sar/cached/{region_id}_{slug}.png"
            out = asset_out_path(rel)
            jobs.append(
                CacheJob(data_id, dataset_id, rel, out, region_id=region_id)
            )
    return jobs


def patch_infra_observations(
    data: dict[str, Any],
    jobs: list[CacheJob],
    *,
    per_observation: bool,
) -> int:
    dataset_mapping: dict[tuple[str, str], str] = {}
    for job in jobs:
        if not job.out_path.is_file() or not job.region_id:
            continue
        dataset_mapping[(job.region_id, job.dataset_id)] = job.asset_rel

    updated = 0
    for region_id, region in (data.get("regions") or {}).items():
        for obs in region.get("observations") or []:
            data_id = obs.get("dataId")
            dataset_id = obs.get("datasetId")
            if per_observation and data_id:
                rel = f"assets/images/sar/cached/{region_id}/{data_id}.png"
                out = asset_out_path(rel)
                if not out.is_file():
                    continue
            elif dataset_id:
                rel = dataset_mapping.get((region_id, dataset_id))
                if not rel:
                    continue
            else:
                continue
            if obs.get("thumbnailUrl") != rel:
                obs["thumbnailUrl"] = rel
                updated += 1
    return updated


def disaster_jobs(data: dict[str, Any]) -> list[CacheJob]:
    jobs: list[CacheJob] = []
    for event in data.get("events") or []:
        event_id = event.get("id") or "event"
        lat = event.get("lat")
        lon = event.get("lon")
        for phase in event.get("phases") or []:
            scene_id = phase.get("sceneId")
            dataset_id = phase.get("datasetId")
            if not scene_id or not dataset_id:
                continue
            label = phase.get("phase") or "phase"
            rel = f"assets/images/disaster/cached/{event_id}_{label}.png"
            out = asset_out_path(rel)
            acq = phase.get("acquisitionDate")
            if not acq:
                continue
            gte, lte = disaster_phase_date_window(label, acq)
            jobs.append(
                CacheJob(
                    scene_id,
                    dataset_id,
                    rel,
                    out,
                    lat=lat,
                    lon=lon,
                    acquisition_gte=gte,
                    acquisition_lte=lte,
                )
            )
    return jobs


def sensor_dataset_map(data: dict[str, Any]) -> dict[str, str]:
    return {
        s["id"]: s["datasetId"]
        for s in (data.get("sensors") or [])
        if s.get("id") and s.get("datasetId")
    }


def multi_sensor_jobs(data: dict[str, Any]) -> list[CacheJob]:
    ds_by_sensor = sensor_dataset_map(data)
    jobs: list[CacheJob] = []
    for site in data.get("sites") or []:
        site_id = site.get("id") or "site"
        lat = site.get("lat")
        lon = site.get("lon")
        for scene in site.get("scenes") or []:
            scene_id = scene.get("sceneId")
            sensor_id = scene.get("sensorId") or "sensor"
            dataset_id = ds_by_sensor.get(sensor_id)
            if not scene_id or not dataset_id:
                continue
            rel = f"assets/images/multi_sensor/cached/{site_id}_{sensor_id}.png"
            out = asset_out_path(rel)
            acq = scene.get("acquisitionDate")
            jobs.append(
                CacheJob(
                    scene_id,
                    dataset_id,
                    rel,
                    out,
                    lat=lat,
                    lon=lon,
                    acquisition_gte=acq,
                    acquisition_lte=acq,
                )
            )
    return jobs


def template_jobs(template_path: Path) -> list[CacheJob]:
    with template_path.open(encoding="utf-8") as f:
        data = json.load(f)
    template_id = data.get("templateId") or template_path.stem
    jobs: list[CacheJob] = []
    for region in (data.get("regions") or {}).values():
        lat = region.get("lat")
        lon = region.get("lon")
        for obs in region.get("observations") or []:
            data_id = obs.get("dataId")
            dataset_id = obs.get("datasetId")
            if not data_id or not dataset_id:
                continue
            rel = f"assets/images/templates/cached/{template_id}/{data_id}.png"
            out = asset_out_path(rel)
            acq = obs.get("acquisitionDate")
            jobs.append(
                CacheJob(
                    data_id,
                    dataset_id,
                    rel,
                    out,
                    lat=lat,
                    lon=lon,
                    acquisition_gte=acq,
                    acquisition_lte=acq,
                )
            )
    return jobs


def run_jobs(
    jobs: list[CacheJob],
    *,
    dry_run: bool,
    skip_existing: bool,
    use_bbox_search: bool,
) -> dict[str, int]:
    load_dotenv(ENV_PATH)
    api_key = os.getenv("TELLUS_API_KEY", "").strip()
    if not api_key:
        print("Error: TELLUS_API_KEY not set (.env)", file=sys.stderr)
        sys.exit(1)

    session = build_session()
    headers = auth_headers(api_key)
    stats: dict[str, int] = {"cached": 0, "skipped": 0, "failed": 0, "dry_run": 0}

    for i, job in enumerate(jobs, 1):
        ok, reason = cache_one(
            session,
            headers,
            job,
            dry_run=dry_run,
            skip_existing=skip_existing,
            use_bbox_search=use_bbox_search,
        )
        if ok:
            stats[reason if reason in stats else "cached"] += 1
        else:
            stats["failed"] += 1
            print(f"  fail [{i}/{len(jobs)}] {job.asset_rel}: {reason}", file=sys.stderr)
        if i % 10 == 0:
            print(f"  progress {i}/{len(jobs)}...")

    return stats


def cache_infrastructure(
    path: Path,
    *,
    mode: str,
    limit: int | None,
    dry_run: bool,
    skip_existing: bool,
) -> None:
    with path.open(encoding="utf-8") as f:
        data = json.load(f)

    per_obs = mode == "per-observation"
    jobs = (
        infra_jobs_by_observation(data, limit=limit)
        if per_obs
        else infra_jobs_by_dataset(data)
    )

    print(f"Infrastructure: {len(jobs)} thumbnail jobs (mode={mode})")
    stats = run_jobs(jobs, dry_run=dry_run, skip_existing=skip_existing, use_bbox_search=False)

    if dry_run:
        print(f"Dry run complete: {stats}")
        return

    updated = patch_infra_observations(data, jobs, per_observation=per_obs)
    meta = data.setdefault("meta", {})
    meta["thumbnailSource"] = "tellus_cached"
    meta["thumbnailCachedAt"] = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"Stats: {stats}")
    print(f"Patched {updated} observations in {path}")


def patch_json_entries(
    path: Path,
    jobs: list[CacheJob],
    walk: Callable[[dict[str, Any]], Iterator[tuple[str, dict[str, Any]]]],
    rel_for: Callable[[dict[str, Any], str, dict[str, Path]], str | None],
) -> int:
    with path.open(encoding="utf-8") as f:
        data = json.load(f)

    files_by_rel = {j.asset_rel: j.out_path for j in jobs}
    updated = 0
    for ctx, item in walk(data):
        rel = rel_for(item, ctx, files_by_rel)
        if rel and item.get("thumbnailUrl") != rel:
            item["thumbnailUrl"] = rel
            updated += 1

    if "generatedAt" in data:
        data["thumbnailSource"] = "tellus_cached"
        data["thumbnailCachedAt"] = datetime.now(timezone.utc).isoformat().replace(
            "+00:00", "Z"
        )

    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    return updated


def cache_disaster(path: Path, *, dry_run: bool, skip_existing: bool, bbox_search: bool) -> None:
    with path.open(encoding="utf-8") as f:
        data = json.load(f)
    jobs = disaster_jobs(data)
    print(f"Disaster archive: {len(jobs)} jobs (bbox_search={bbox_search})")
    stats = run_jobs(
        jobs, dry_run=dry_run, skip_existing=skip_existing, use_bbox_search=bbox_search
    )
    if dry_run:
        print(f"Dry run complete: {stats}")
        return

    def walk(d: dict[str, Any]) -> Iterator[tuple[str, dict[str, Any]]]:
        for event in d.get("events") or []:
            eid = event.get("id") or ""
            for phase in event.get("phases") or []:
                yield eid, phase

    def rel_for(phase: dict[str, Any], event_id: str, files: dict[str, Path]) -> str | None:
        label = phase.get("phase") or "phase"
        rel = f"assets/images/disaster/cached/{event_id}_{label}.png"
        return rel if files.get(rel) and files[rel].is_file() else None

    updated = patch_json_entries(path, jobs, walk, rel_for)

    with path.open(encoding="utf-8") as f:
        data = json.load(f)
    scene_updates = 0
    job_by_rel = {j.asset_rel: j for j in jobs}
    for event in data.get("events") or []:
        eid = event.get("id") or ""
        for phase in event.get("phases") or []:
            label = phase.get("phase") or "phase"
            rel = f"assets/images/disaster/cached/{eid}_{label}.png"
            job = job_by_rel.get(rel)
            if not job or not job.resolved_data_id:
                continue
            if phase.get("sceneId") != job.resolved_data_id:
                phase["sceneId"] = job.resolved_data_id
                scene_updates += 1
            if job.resolved_dataset_id and phase.get("datasetId") != job.resolved_dataset_id:
                phase["datasetId"] = job.resolved_dataset_id
    if scene_updates:
        data["thumbnailCachedAt"] = datetime.now(timezone.utc).isoformat().replace(
            "+00:00", "Z"
        )
        with path.open("w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")

    print(f"Stats: {stats}")
    print(f"Patched {updated} thumbnail URLs, {scene_updates} scene IDs in {path}")


def cache_multi_sensor(
    path: Path, *, dry_run: bool, skip_existing: bool, bbox_search: bool
) -> None:
    with path.open(encoding="utf-8") as f:
        data = json.load(f)
    jobs = multi_sensor_jobs(data)
    print(f"Multi-sensor: {len(jobs)} jobs (bbox_search={bbox_search})")
    stats = run_jobs(
        jobs, dry_run=dry_run, skip_existing=skip_existing, use_bbox_search=bbox_search
    )
    if dry_run:
        print(f"Dry run complete: {stats}")
        return

    def walk(d: dict[str, Any]) -> Iterator[tuple[str, dict[str, Any]]]:
        for site in d.get("sites") or []:
            sid = site.get("id") or ""
            for scene in site.get("scenes") or []:
                yield sid, scene

    def rel_for(scene: dict[str, Any], site_id: str, files: dict[str, Path]) -> str | None:
        sensor_id = scene.get("sensorId") or "sensor"
        rel = f"assets/images/multi_sensor/cached/{site_id}_{sensor_id}.png"
        return rel if files.get(rel) and files[rel].is_file() else None

    updated = patch_json_entries(path, jobs, walk, rel_for)
    print(f"Stats: {stats}")
    print(f"Patched {updated} sensors in {path}")


def cache_templates(
    templates_dir: Path, *, dry_run: bool, skip_existing: bool, bbox_search: bool
) -> None:
    paths = sorted(p for p in templates_dir.glob("*.json") if p.name != "index.json")
    jobs: list[CacheJob] = []
    for p in paths:
        jobs.extend(template_jobs(p))

    print(f"Templates: {len(jobs)} jobs across {len(paths)} files (bbox_search={bbox_search})")
    stats = run_jobs(
        jobs, dry_run=dry_run, skip_existing=skip_existing, use_bbox_search=bbox_search
    )
    if dry_run:
        print(f"Dry run complete: {stats}")
        return

    files_by_rel = {j.asset_rel: j.out_path for j in jobs}
    for p in paths:
        with p.open(encoding="utf-8") as f:
            data = json.load(f)
        template_id = data.get("templateId") or p.stem
        updated = 0
        for region in (data.get("regions") or {}).values():
            for obs in region.get("observations") or []:
                data_id = obs.get("dataId")
                if not data_id:
                    continue
                rel = f"assets/images/templates/cached/{template_id}/{data_id}.png"
                if files_by_rel.get(rel) and files_by_rel[rel].is_file():
                    if obs.get("thumbnailUrl") != rel:
                        obs["thumbnailUrl"] = rel
                        updated += 1
        if updated:
            with p.open("w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                f.write("\n")
            print(f"  {p.name}: patched {updated}")

    print(f"Stats: {stats}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Cache Tellus SAR thumbnails as bundled assets")
    parser.add_argument(
        "--target",
        choices=("infrastructure", "disaster", "multi_sensor", "templates", "all"),
        default="infrastructure",
    )
    parser.add_argument(
        "--mode",
        choices=("by-dataset", "per-observation"),
        default="by-dataset",
        help="infrastructure のみ: 代表1枚/観測ごと",
    )
    parser.add_argument("--limit", type=int, default=None, help="per-observation 時の最大件数")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--skip-existing", action="store_true", default=True)
    parser.add_argument("--no-skip-existing", dest="skip_existing", action="store_false")
    parser.add_argument(
        "--bbox-search",
        action="store_true",
        help="合成 ID 向け: 座標+BBOX で実シーンを検索してから取得",
    )
    parser.add_argument("--infra-path", type=Path, default=DEFAULT_INFRA)
    args = parser.parse_args()

    bbox = args.bbox_search or args.target in ("disaster", "multi_sensor", "templates", "all")
    data_root = PROJECT_ROOT / "web_app" / "assets" / "data"

    if args.target in ("infrastructure", "all"):
        cache_infrastructure(
            args.infra_path,
            mode=args.mode,
            limit=args.limit,
            dry_run=args.dry_run,
            skip_existing=args.skip_existing,
        )
    if args.target in ("disaster", "all"):
        cache_disaster(
            data_root / "disaster_archive.json",
            dry_run=args.dry_run,
            skip_existing=args.skip_existing,
            bbox_search=bbox,
        )
    if args.target in ("multi_sensor", "all"):
        cache_multi_sensor(
            data_root / "multi_sensor.json",
            dry_run=args.dry_run,
            skip_existing=args.skip_existing,
            bbox_search=bbox,
        )
    if args.target in ("templates", "all"):
        cache_templates(
            data_root / "templates",
            dry_run=args.dry_run,
            skip_existing=args.skip_existing,
            bbox_search=True,
        )


if __name__ == "__main__":
    main()
