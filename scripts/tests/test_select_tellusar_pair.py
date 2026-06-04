import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "pipeline"))

from select_tellusar_pair import suggest_pair  # noqa: E402


def test_suggest_pair_finds_two_ids():
    data = {
        "regions": {
            "tateyama": {
                "observations": [
                    {
                        "dataId": "a",
                        "orbitDirection": "ascending",
                        "polarization": "HH",
                        "acquisitionDate": "2020-01-01",
                        "start_datetime": "2020-01-01T00:00:00Z",
                        "monitoringIndex": 0.2,
                    },
                    {
                        "dataId": "b",
                        "orbitDirection": "ascending",
                        "polarization": "HH",
                        "acquisitionDate": "2024-06-01",
                        "start_datetime": "2024-06-01T00:00:00Z",
                        "monitoringIndex": 0.8,
                    },
                ]
            }
        }
    }
    pair = suggest_pair(data)
    assert pair is not None
    assert pair["dataIds"] == ["a", "b"]
