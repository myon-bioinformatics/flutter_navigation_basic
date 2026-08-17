#!/usr/bin/env python3
"""Verify committed timezone reference cases against Python stdlib zoneinfo."""

from __future__ import annotations

import json
import sys
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

FIXTURE_PATH = Path(__file__).with_name("fixtures") / "timezone_cases.json"
REQUIRED_CASE_KEYS = {"zone", "utc", "local", "offset_minutes", "is_dst"}


def fail(message: str) -> int:
    print(f"timezone verification failed: {message}", file=sys.stderr)
    return 1


def main() -> int:
    try:
        payload = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return fail(str(exc))

    if payload.get("schema_version") != 1:
        return fail("unsupported or missing schema_version")

    zones = payload.get("zones")
    cases = payload.get("cases")
    if not isinstance(zones, list) or not zones:
        return fail("zones must be a non-empty list")
    if not isinstance(cases, list) or not cases:
        return fail("cases must be a non-empty list")

    seen_zones: set[str] = set()
    for index, case in enumerate(cases):
        if not isinstance(case, dict) or not REQUIRED_CASE_KEYS.issubset(case):
            return fail(f"case {index} is missing required fields")

        zone_name = case["zone"]
        if not isinstance(zone_name, str):
            return fail(f"case {index} zone is not a string")
        try:
            zone = ZoneInfo(zone_name)
        except ZoneInfoNotFoundError:
            return fail(f"IANA timezone data is unavailable for {zone_name}")

        try:
            utc = datetime.fromisoformat(case["utc"])
        except (TypeError, ValueError) as exc:
            return fail(f"case {index} has invalid UTC timestamp: {exc}")
        if utc.utcoffset() is None or utc.utcoffset().total_seconds() != 0:
            return fail(f"case {index} UTC timestamp must have +00:00 offset")

        local = utc.astimezone(zone)
        offset = local.utcoffset()
        dst = local.dst()
        actual = {
            "local": local.isoformat(),
            "offset_minutes": int(offset.total_seconds() // 60) if offset else 0,
            "is_dst": bool(dst and dst.total_seconds() != 0),
        }
        expected = {key: case[key] for key in actual}
        if actual != expected:
            return fail(
                f"case {index} {zone_name} {case['utc']} expected {expected}, got {actual}"
            )
        seen_zones.add(zone_name)

    if seen_zones != set(zones):
        return fail("zones list does not match zones represented by cases")

    print(f"Verified {len(cases)} timezone cases across {len(zones)} IANA zones.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
