#!/usr/bin/env python3
"""Send pipeline notifications via Slack webhook."""

from __future__ import annotations

import json
import os
import sys
import urllib.request
from pathlib import Path

from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
ENV_PATH = PROJECT_ROOT / ".env"


def send_slack(webhook_url: str, message: str) -> bool:
    payload = json.dumps({"text": message}).encode("utf-8")
    req = urllib.request.Request(
        webhook_url,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.status == 200


def notify_pipeline_result(
    *,
    status: str,
    summary: str,
    details: dict | None = None,
) -> None:
    load_dotenv(ENV_PATH)
    webhook = os.getenv("SLACK_WEBHOOK_URL", "").strip()
    if not webhook:
        print("SLACK_WEBHOOK_URL not set — skipping notification")
        return

    lines = [f"*Tellus Pipeline* [{status}]", summary]
    if details:
        for k, v in details.items():
            lines.append(f"• {k}: {v}")

    message = "\n".join(lines)
    if send_slack(webhook, message):
        print("Notification sent")
    else:
        print("Notification failed", file=sys.stderr)


def main() -> None:
    status = sys.argv[1] if len(sys.argv) > 1 else "info"
    summary = sys.argv[2] if len(sys.argv) > 2 else "Pipeline run complete"
    notify_pipeline_result(status=status, summary=summary)


if __name__ == "__main__":
    main()
