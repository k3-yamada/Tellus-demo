import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "pipeline"))

from merge_tellusar_result import merge_result  # noqa: E402


def test_merge_result():
    data = {"meta": {}}
    job = {
        "regionId": "tateyama",
        "values": [{"date": "2020-01-01", "displacementMm": -1.0}],
    }
    merge_result(data, job)
    assert data["meta"]["displacementDemo"]["values"][0]["displacementMm"] == -1.0
