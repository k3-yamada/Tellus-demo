"""Tests for cache_thumbnails pipeline module."""

from __future__ import annotations

import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "pipeline"))

from cache_thumbnails import (  # noqa: E402
    CacheJob,
    asset_out_path,
    bbox_polygon,
    disaster_jobs,
    disaster_phase_date_window,
    infra_jobs_by_dataset,
    patch_infra_observations,
    sensor_dataset_map,
)

PNG_MAGIC = bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])


def test_bbox_polygon_ring_closed():
    ring = bbox_polygon(137.34, 36.598)["coordinates"][0]
    assert ring[0] == ring[-1]


def test_asset_out_path():
    with patch("cache_thumbnails.PROJECT_ROOT", Path("/proj")):
        path = asset_out_path("assets/images/sar/cached/foo.png")
    assert path == Path("/proj/web_app/assets/images/sar/cached/foo.png")


def test_infra_jobs_by_dataset_dedupes():
    data = {
        "regions": {
            "joganji": {
                "observations": [
                    {"dataId": "aaa", "datasetId": "ds-1"},
                    {"dataId": "bbb", "datasetId": "ds-1"},
                ]
            }
        }
    }
    assert len(infra_jobs_by_dataset(data)) == 1


def test_sensor_dataset_map():
    data = {"sensors": [{"id": "palsar2_l21", "datasetId": "ds-1"}]}
    assert sensor_dataset_map(data) == {"palsar2_l21": "ds-1"}


def test_disaster_phase_date_window():
    gte, lte = disaster_phase_date_window("during", "2024-01-03")
    assert gte == "2023-12-27"
    assert lte == "2024-01-10"
    gte_b, lte_b = disaster_phase_date_window("before", "2024-01-03")
    assert lte_b == "2024-01-03"
    assert gte_b < lte_b


def test_disaster_jobs_paths():
    data = {
        "events": [{
            "id": "noto_2024",
            "lat": 37.5,
            "lon": 137.2,
            "phases": [{
                "phase": "before",
                "sceneId": "scene-1",
                "datasetId": "ds-1",
                "acquisitionDate": "2023-12-25",
            }],
        }]
    }
    jobs = disaster_jobs(data)
    assert jobs[0].asset_rel.endswith("noto_2024_before.png")
    assert jobs[0].acquisition_gte == "2023-11-25"
    assert jobs[0].acquisition_lte == "2023-12-25"


def test_patch_infra_by_dataset(tmp_path: Path):
    root = tmp_path
    rel = "assets/images/sar/cached/joganji_palsar2_l21.png"
    out = root / "web_app" / rel
    out.parent.mkdir(parents=True)
    out.write_bytes(PNG_MAGIC)
    job = CacheJob("data-1", "ds-1", rel, out, region_id="joganji")
    data = {
        "regions": {
            "joganji": {
                "observations": [
                    {"dataId": "data-1", "datasetId": "ds-1", "thumbnailUrl": "old"},
                ]
            }
        }
    }
    with patch("cache_thumbnails.PROJECT_ROOT", root):
        updated = patch_infra_observations(data, [job], per_observation=False)
    assert updated == 1


def test_cache_one_skips_existing(tmp_path: Path):
    from cache_thumbnails import cache_one  # noqa: E402

    out = tmp_path / "thumb.png"
    out.write_bytes(b"png")
    job = CacheJob("id", "ds", "assets/x.png", out)
    ok, reason = cache_one(
        MagicMock(), {}, job, dry_run=False, skip_existing=True, use_bbox_search=False
    )
    assert ok and reason == "skipped"
