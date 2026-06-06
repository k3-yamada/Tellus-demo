"""ダッシュボード用 SAR サムネイルを合成 PNG として生成し、
infrastructure_data.json の thumbnailUrl をバンドル資産パスに差し替える。
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from demo_png import make_sar_pixels, write_gray_png

ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_PATH = ROOT / "web_app" / "assets" / "data" / "infrastructure_data.json"
THUMB_DIR = ROOT / "web_app" / "assets" / "images" / "sar"

DATASET_SLUG = {
    "1a41a4b1-4594-431f-95fb-82f9bdc35d6b": "palsar2_l21",
    "b0e16dea-6544-4422-926f-ad3ec9a3fcbd": "palsar2_scansar",
    "45ff087d-be02-4788-bc4c-28cd947a1167": "palsar2_slc",
    "ab4cd6a5-4ac9-4656-a5b5-a782ea0885c7": "alpsmlc30",
}

REGION_IDS = ("joganji", "tateyama")


def asset_path(region_id: str, dataset_id: str) -> str:
    slug = DATASET_SLUG.get(dataset_id, "generic")
    return f"assets/images/sar/{region_id}_{slug}.png"


def ensure_thumbnails() -> dict[tuple[str, str], str]:
    mapping: dict[tuple[str, str], str] = {}
    for region_id in REGION_IDS:
        for dataset_id, slug in DATASET_SLUG.items():
            rel = asset_path(region_id, dataset_id)
            out = THUMB_DIR / f"{region_id}_{slug}.png"
            coarse = slug == "palsar2_scansar"
            write_gray_png(
                out,
                320,
                200,
                make_sar_pixels(f"{region_id}:{slug}", coarse=coarse),
            )
            mapping[(region_id, dataset_id)] = rel
    return mapping


def patch_observations(data: dict, mapping: dict[tuple[str, str], str]) -> int:
    updated = 0
    for region_id, region in (data.get("regions") or {}).items():
        for obs in region.get("observations") or []:
            dataset_id = obs.get("datasetId")
            rel = mapping.get((region_id, dataset_id))
            if rel is None:
                rel = f"assets/images/demo/sar_fallback.png"
            if obs.get("thumbnailUrl") != rel:
                obs["thumbnailUrl"] = rel
                updated += 1
    return updated


def main() -> None:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PATH
    with path.open(encoding="utf-8") as f:
        data = json.load(f)

    mapping = ensure_thumbnails()
    count = patch_observations(data, mapping)

    meta = data.setdefault("meta", {})
    meta["thumbnailSource"] = "bundled_demo_png"
    meta["thumbnailGeneratedAt"] = (
        datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    )

    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"Wrote {len(mapping)} SAR thumbnails under {THUMB_DIR}")
    print(f"Patched {count} observations in {path}")


if __name__ == "__main__":
    main()
