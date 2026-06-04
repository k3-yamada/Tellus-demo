"""Tests for pipeline quality_report module."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "pipeline"))

from quality_report import (  # noqa: E402
    build_coverage_by_year,
    build_quality_report,
    compute_quality_score,
    enrich_v2_fields,
)


def test_compute_quality_score_full():
    obs = {
        "dataId": "abc",
        "acquisitionDate": "2020-01-01",
        "orbitDirection": "ascending",
        "polarization": "HH",
        "relativeOrbit": 19,
        "offNadir": 38.6,
        "geometry": {"type": "Polygon"},
        "thumbnailUrl": "https://example.com/t.jpg",
    }
    score = compute_quality_score(obs)
    assert score == 1.0


def test_compute_quality_score_minimal():
    obs = {"dataId": "abc", "acquisitionDate": "2020-01-01"}
    score = compute_quality_score(obs)
    assert 0.3 <= score <= 0.5


def test_build_coverage_by_year():
    data = {
        "regions": {
            "joganji": {
                "observations": [
                    {"acquisitionDate": "2018-03-01"},
                    {"acquisitionDate": "2019-06-01"},
                ]
            }
        }
    }
    coverage = build_coverage_by_year(data)
    assert coverage["joganji"]["2018"] == 1
    assert coverage["joganji"]["2019"] == 1


def test_enrich_v2_fields():
    data = {
        "meta": {},
        "regions": {
            "tateyama": {
                "observations": [{"dataId": "x", "acquisitionDate": "2020-01-01"}]
            }
        },
        "timeline": [],
    }
    result = enrich_v2_fields(data)
    assert result["schemaVersion"] == 2
    assert "qualityReport" in result
    assert "coverageByYear" in result
    assert result["meta"]["displacementDemo"]["regionId"] == "tateyama"


def test_build_quality_report():
    data = {
        "regions": {
            "a": {
                "observations": [
                    {"dataId": "1", "acquisitionDate": "2020-01-01", "orbitDirection": "asc"},
                ]
            }
        }
    }
    report = build_quality_report(data)
    assert report["totalObservations"] == 1
    assert 0 <= report["overallScore"] <= 1
