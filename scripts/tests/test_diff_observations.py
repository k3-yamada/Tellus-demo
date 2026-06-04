"""Tests for diff_observations."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "pipeline"))

from diff_observations import diff_observations  # noqa: E402


def test_diff_detects_new_ids():
    before = {
        "regions": {
            "a": {"observations": [{"dataId": "1"}, {"dataId": "2"}]},
        }
    }
    after = {
        "regions": {
            "a": {"observations": [{"dataId": "1"}, {"dataId": "2"}, {"dataId": "3"}]},
        }
    }
    diff = diff_observations(before, after)
    assert diff["totalNew"] == 1
    assert diff["perRegion"]["a"] == 1
