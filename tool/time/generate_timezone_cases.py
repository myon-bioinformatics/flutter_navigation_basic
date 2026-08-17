#!/usr/bin/env python3
"""Generate deterministic IANA timezone reference cases for Dart tests.

This is development tooling only. Runtime Flutter code must not depend on Python.
The script intentionally uses only the Python standard library.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

ZONES = (
    "Asia/Tokyo",
    "Europe/London",
    "America/New_York",
)

# UTC instants cover ordinary winter/summer dates plus both sides of the 2026
# London and New York DST transitions. Keeping the source instants explicit
# makes this fixture deterministic and reviewable.
UTC_INSTANTS = (
    "2026-01-15T12:00:00+00:00",
    "2026-03-08T06:59:00+00:00",
    "2026-03-08T07:01:00+00:00",
    "2026-03-29T00:59:00+00:00",
    "2026-03-29T01:01:00+00:00",
    "2026-07-15T12:00:00+00:00",
    "2026-10-25T00:59:00+00:00",
    "2026-10-25T01:01:00+00:00",
    "2026-11-01T05:59:00+00:00",
    "2026-11-01T06:01:00+00:00",
)

FIXTURE_PATH = Path(__file__).with_name("fixtures") / "timezone_cases.json"


def _zone(name: str) -> ZoneInfo:
    try:
        return ZoneInfo(name)
    except ZoneInfoNotFoundError as exc:
        raise SystemExit(
            f"IANA timezone data for {name!r} is unavailable in this Python environment."
        ) from exc


def build_fixture() -> dict[str, object]:
    cases: list[dict[str, object]] = []
    for zone_name in ZONES:
        zone = _zone(zone_name)
        for utc_text in UTC_INSTANTS:
            utc = datetime.fromisoformat(utc_text)
            local = utc.astimezone(zone)
            offset = local.utcoffset()
            dst = local.dst()
            if offset is None:
                raise SystemExit(f"No UTC offset resolved for {zone_name} at {utc_text}")
            cases.append(
                {
                    "zone": zone_name,
                    "utc": utc.isoformat(),
                    "local": local.isoformat(),
                    "offset_minutes": int(offset.total_seconds() // 60),
                    "is_dst": bool(dst and dst.total_seconds() != 0),
                }
            )

    return {
        "schema_version": 1,
        "source": "Python stdlib zoneinfo / system IANA tzdata",
        "zones": list(ZONES),
        "cases": cases,
    }


def render_fixture() -> str:
    return json.dumps(build_fixture(), ensure_ascii=False, indent=2) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="Fail if the committed fixture differs from current zoneinfo output.",
    )
    parser.add_argument(
        "--stdout",
        action="store_true",
        help="Print generated JSON instead of writing the fixture.",
    )
    args = parser.parse_args()

    rendered = render_fixture()
    if args.stdout:
        sys.stdout.write(rendered)
        return 0

    if args.check:
        if not FIXTURE_PATH.exists():
            print(f"Missing fixture: {FIXTURE_PATH}", file=sys.stderr)
            return 1
        current = FIXTURE_PATH.read_text(encoding="utf-8")
        if current != rendered:
            print(
                "Timezone fixture is stale. Run "
                "`python3 tool/time/generate_timezone_cases.py` and commit the result.",
                file=sys.stderr,
            )
            return 1
        print(f"Timezone fixture is current: {FIXTURE_PATH}")
        return 0

    FIXTURE_PATH.parent.mkdir(parents=True, exist_ok=True)
    FIXTURE_PATH.write_text(rendered, encoding="utf-8")
    print(f"Wrote {FIXTURE_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
