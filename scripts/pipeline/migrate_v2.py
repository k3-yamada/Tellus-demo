#!/usr/bin/env python3
"""Migrate existing infrastructure_data.json to schema v2 without re-fetch."""

from __future__ import annotations

import json
import sys
from pathlib import Path

from quality_report import enrich_v2_fields

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
DEFAULT_INPUT = PROJECT_ROOT / "web_app" / "assets" / "data" / "infrastructure_data.json"


def migrate(path: Path) -> None:
    with path.open(encoding="utf-8") as f:
        data = json.load(f)

    if data.get("schemaVersion") == 2:
        print(f"Already v2: {path}")
        return

    enrich_v2_fields(data)

    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"Migrated to v2: {path}")
    print(f"  qualityReport.overallScore={data['qualityReport']['overallScore']}")
    print(f"  coverageByYear regions={list(data['coverageByYear'].keys())}")


def main() -> None:
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_INPUT
    if not target.exists():
        print(f"Error: {target} not found", file=sys.stderr)
        sys.exit(1)
    migrate(target)


if __name__ == "__main__":
    main()
