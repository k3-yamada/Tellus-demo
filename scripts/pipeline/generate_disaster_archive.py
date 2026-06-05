"""災害アーカイブ JSON 生成器。

3 件の災害について、Tellus 衛星観測の事前/当日/事後シーンメタを
固定で並べる。Tellus dataset ID は実在 (PALSAR-2)。シーン ID と
取得時刻は本デモ用の合成データ (synthesized) である旨を明示する。
"""

from __future__ import annotations

import hashlib
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

OUT_PATH = (
    Path(__file__).resolve().parent.parent.parent
    / "web_app"
    / "assets"
    / "data"
    / "disaster_archive.json"
)

PALSAR2_DATASET = "1a41a4b1-4594-431f-95fb-82f9bdc35d6b"
PALSAR2_SCANSAR = "b0e16dea-6544-4422-926f-ad3ec9a3fcbd"


def make_scene_id(seed: str) -> str:
    h = hashlib.sha1(seed.encode()).hexdigest()
    return f"{h[0:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:32]}"


def phase(
    event_id: str,
    label: str,
    days_offset: int,
    event_iso: str,
    dataset_id: str,
    orbit: str,
    polarization: str,
    note: str,
) -> dict:
    event_dt = datetime.fromisoformat(event_iso.replace("Z", "+00:00"))
    scene_dt = event_dt + timedelta(days=days_offset)
    return {
        "phase": label,
        "datasetId": dataset_id,
        "sceneId": make_scene_id(f"{event_id}-{label}-{dataset_id}"),
        "acquisitionDate": scene_dt.date().isoformat(),
        "acquisitionDatetime": scene_dt.isoformat().replace("+00:00", "Z"),
        "orbitDirection": orbit,
        "polarization": polarization,
        "thumbnailUrl": None,
        "note": note,
    }


EVENTS = [
    {
        "id": "noto_2024",
        "name": "令和6年能登半島地震",
        "summary": "2024年元日のM7.6地震。輪島・珠洲を中心に大規模な隆起と土砂崩れが発生。SAR は雲・夜間に関係なく被災直後の全体像を捕捉できる。",
        "lat": 37.4980,
        "lon": 137.2730,
        "eventDatetime": "2024-01-01T16:10:00Z",
        "phases": [
            phase("noto_2024", "before", -7, "2024-01-01T16:10:00Z", PALSAR2_DATASET, "ascending", "HH+HV",
                  "発災 7 日前の通常観測"),
            phase("noto_2024", "during", 2, "2024-01-01T16:10:00Z", PALSAR2_SCANSAR, "ascending", "HH",
                  "発災 2 日後、JAXA 緊急観測 (ScanSAR で広域把握)"),
            phase("noto_2024", "after", 30, "2024-01-01T16:10:00Z", PALSAR2_DATASET, "descending", "HH+HV",
                  "1 ヶ月後、隆起・土砂崩れの全容観測"),
        ],
        "demoFocus": "海岸線の隆起・斜面崩壊",
    },
    {
        "id": "nishinihon_2018",
        "name": "平成30年7月豪雨 (西日本豪雨)",
        "summary": "2018年7月の記録的豪雨で広島・岡山・愛媛が広範囲冠水。光学は雲で見えないが SAR で浸水域を即座に把握。",
        "lat": 34.5867,
        "lon": 133.6803,
        "eventDatetime": "2018-07-06T00:00:00Z",
        "phases": [
            phase("nishinihon_2018", "before", -14, "2018-07-06T00:00:00Z", PALSAR2_DATASET, "ascending", "HH+HV",
                  "豪雨前 2 週間の平常時"),
            phase("nishinihon_2018", "during", 2, "2018-07-06T00:00:00Z", PALSAR2_SCANSAR, "descending", "HH",
                  "豪雨翌々日、真備町の浸水を ScanSAR で観測"),
            phase("nishinihon_2018", "after", 21, "2018-07-06T00:00:00Z", PALSAR2_DATASET, "ascending", "HH+HV",
                  "3 週間後の浸水退潮確認"),
        ],
        "demoFocus": "広域浸水域の検出 (SAR が雲を抜く)",
    },
    {
        "id": "atami_2021",
        "name": "令和3年熱海伊豆山土砂災害",
        "summary": "2021年7月3日に熱海市伊豆山で発生した土石流。発災前後の地表変化を SAR で評価。",
        "lat": 35.1167,
        "lon": 139.0667,
        "eventDatetime": "2021-07-03T00:00:00Z",
        "phases": [
            phase("atami_2021", "before", -10, "2021-07-03T00:00:00Z", PALSAR2_DATASET, "ascending", "HH+HV",
                  "発災 10 日前の通常観測"),
            phase("atami_2021", "during", 3, "2021-07-03T00:00:00Z", PALSAR2_DATASET, "descending", "HH+HV",
                  "発災 3 日後、土砂流出域の観測"),
            phase("atami_2021", "after", 45, "2021-07-03T00:00:00Z", PALSAR2_DATASET, "ascending", "HH+HV",
                  "1.5 ヶ月後、復旧進捗の確認"),
        ],
        "demoFocus": "局所斜面の土砂流出パターン",
    },
]


def main() -> None:
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "schemaVersion": 1,
        "generatedAt": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "disclaimer": (
            "本デモのシーン ID と取得時刻は合成データです。Tellus dataset ID は実在しますが、"
            "個別シーンの配信状況は Tellus 側で確認が必要です。"
        ),
        "events": EVENTS,
    }
    with OUT_PATH.open("w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    print(f"wrote {OUT_PATH}")


if __name__ == "__main__":
    main()
