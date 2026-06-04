#!/usr/bin/env python3
"""Print JSON summary for Slack notifications after a pipeline run."""

from __future__ import annotations

import json
import sys
from pathlib import Path

from diff_observations import diff_observations, load_json, summarize_quality

DEFAULT_PATH = Path(__file__).resolve().parent.parent.parent / "web_app" / "assets" / "data" / "infrastructure_data.json"
PREVIOUS_SUFFIX = ".previous.json"


def main() -> None:
    current_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PATH
    previous_path = current_path.with_suffix(PREVIOUS_SUFFIX)
    current = load_json(current_path)
    summary = summarize_quality(current)
    payload: dict = {"summary": summary}
    if previous_path.exists():
        previous = load_json(previous_path)
        payload["diff"] = diff_observations(previous, current)
    print(json.dumps(payload, ensure_ascii=False))


if __name__ == "__main__":
    main()
