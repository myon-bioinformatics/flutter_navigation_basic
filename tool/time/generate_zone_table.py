#!/usr/bin/env python3
"""Generate the region-representative IANA timezone transition table.

Development tooling only: the Flutter app reads the generated JSON asset and
never runs Python. Uses only the Python standard library (zoneinfo + system
IANA tzdata), so the table has no hand-written DST rules.

    python3 tool/time/generate_zone_table.py           # write the asset
    python3 tool/time/generate_zone_table.py --check   # CI drift check
    python3 tool/time/generate_zone_table.py --stdout  # print without writing
"""

from __future__ import annotations

import argparse
import json
import sys
import zoneinfo
from datetime import datetime, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

ROOT = Path(__file__).resolve().parents[2]
ASSET_PATH = ROOT / "assets" / "time" / "zone_table.json"

# Region -> representative zones for the picker. Regions, not countries.
REGIONS: dict[str, tuple[str, ...]] = {
    "UTC": ("UTC",),
    "Asia": (
        "Asia/Tokyo",
        "Asia/Shanghai",
        "Asia/Singapore",
        "Asia/Kolkata",
        "Asia/Kathmandu",
        "Asia/Dubai",
    ),
    "Europe": ("Europe/London", "Europe/Paris", "Europe/Istanbul", "Europe/Moscow"),
    "Africa": ("Africa/Lagos", "Africa/Cairo", "Africa/Johannesburg"),
    "North America": (
        "America/New_York",
        "America/Chicago",
        "America/Denver",
        "America/Los_Angeles",
        "America/Mexico_City",
        "Pacific/Honolulu",
    ),
    "South America": ("America/Sao_Paulo", "America/Argentina/Buenos_Aires"),
    "Oceania": ("Australia/Sydney", "Australia/Perth", "Pacific/Auckland"),
}

# Fixed window keeps output deterministic. Move it deliberately, not by date.
WINDOW_START = datetime(2000, 1, 1, tzinfo=timezone.utc)
WINDOW_END = datetime(2038, 1, 1, tzinfo=timezone.utc)

# Scan step. Assumes no zone changes offset twice within one step; the
# verification below re-checks every transition and evenly spaced samples.
SCAN_STEP = timedelta(hours=6)
VERIFY_SAMPLES_PER_ZONE = 2000


def fail(message: str) -> int:
    print(f"zone table: {message}", file=sys.stderr)
    return 1


def tzdata_version() -> str | None:
    """Return the IANA release of the tzdata that zoneinfo uses, if discoverable."""
    for directory in zoneinfo.TZPATH:
        marker = Path(directory) / "tzdata.zi"
        try:
            first_line = marker.read_text(encoding="utf-8").splitlines()[0]
        except (OSError, IndexError):
            continue
        if first_line.startswith("# version "):
            return first_line.removeprefix("# version ").strip()
    return None


def _zone(name: str) -> ZoneInfo:
    try:
        return ZoneInfo(name)
    except ZoneInfoNotFoundError as exc:
        raise SystemExit(f"zone table: IANA timezone data for {name!r} is unavailable") from exc


def _state(zone: ZoneInfo, instant: datetime) -> tuple[int, bool]:
    local = instant.astimezone(zone)
    offset = local.utcoffset()
    dst = local.dst()
    if offset is None:
        raise SystemExit(f"zone table: no UTC offset for {zone.key} at {instant.isoformat()}")
    return int(offset.total_seconds() // 60), bool(dst and dst.total_seconds() != 0)


def _transitions(name: str) -> list[list[int]]:
    """[[utc_epoch_seconds, offset_minutes, is_dst(0/1)], ...].

    The first row is the state at WINDOW_START, not a real transition.
    """
    zone = _zone(name)
    instant = WINDOW_START
    previous = _state(zone, instant)
    rows = [[int(instant.timestamp()), previous[0], int(previous[1])]]
    while instant < WINDOW_END:
        following = min(instant + SCAN_STEP, WINDOW_END)
        current = _state(zone, following)
        if current != previous and following < WINDOW_END:
            low, high = instant, following
            while high - low > timedelta(seconds=1):
                middle = low + (high - low) / 2
                if _state(zone, middle) == previous:
                    low = middle
                else:
                    high = middle
            change = high.replace(microsecond=0)
            if _state(zone, change) != current:
                change += timedelta(seconds=1)
            rows.append([int(change.timestamp()), current[0], int(current[1])])
            previous = current
        instant = following
    return rows


def _lookup(rows: list[list[int]], epoch: int) -> tuple[int, bool]:
    low, high = 0, len(rows) - 1
    while low < high:
        middle = (low + high + 1) // 2
        if rows[middle][0] <= epoch:
            low = middle
        else:
            high = middle - 1
    return rows[low][1], bool(rows[low][2])


def verify(table: dict[str, object]) -> None:
    """Re-check the table against zoneinfo at every transition +/-1 s and even samples."""
    start = int(WINDOW_START.timestamp())
    span = int(WINDOW_END.timestamp()) - start
    for name, entry in table["zones"].items():  # type: ignore[union-attr]
        rows = entry["transitions"]
        zone = _zone(name)
        points = [row[0] + delta for row in rows[1:] for delta in (-1, 0, 1)]
        points.append(start + span - 1)
        points += [start + span * i // VERIFY_SAMPLES_PER_ZONE for i in range(VERIFY_SAMPLES_PER_ZONE)]
        for epoch in points:
            expected = _state(zone, datetime.fromtimestamp(epoch, timezone.utc))
            actual = _lookup(rows, epoch)
            if actual != expected:
                raise SystemExit(
                    f"zone table: {name} at {epoch}: table {actual}, zoneinfo {expected}"
                )


def build_table() -> dict[str, object]:
    names = [name for zones in REGIONS.values() for name in zones]
    if len(names) != len(set(names)):
        raise SystemExit("zone table: a zone is listed in more than one region")
    table: dict[str, object] = {
        "schema_version": 1,
        "source": "Python stdlib zoneinfo / system IANA tzdata",
        "tzdata_version": tzdata_version(),
        "window_utc": [WINDOW_START.isoformat(), WINDOW_END.isoformat()],
        "row_format": ["utc_epoch_seconds", "offset_minutes", "is_dst"],
        "regions": {region: list(zones) for region, zones in REGIONS.items()},
        "zones": {name: {"transitions": _transitions(name)} for name in names},
    }
    verify(table)
    return table


def render(table: dict[str, object]) -> str:
    """Stable JSON with one transition per line, for readable diffs."""
    lines = ["{"]
    header_keys = [key for key in table if key != "zones"]
    for key in header_keys:
        lines.append(f"  {json.dumps(key)}: {json.dumps(table[key], ensure_ascii=False)},")
    lines.append('  "zones": {')
    zones = table["zones"]  # type: ignore[assignment]
    for zone_index, (name, entry) in enumerate(zones.items()):  # type: ignore[union-attr]
        rows = entry["transitions"]
        lines.append(f"    {json.dumps(name)}: {{")
        lines.append('      "transitions": [')
        for row_index, row in enumerate(rows):
            comma = "," if row_index < len(rows) - 1 else ""
            lines.append(f"        {json.dumps(row)}{comma}")
        lines.append("      ]")
        lines.append("    }" + ("," if zone_index < len(zones) - 1 else ""))
    lines.append("  }")
    lines.append("}")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="Fail if the committed asset is stale.")
    parser.add_argument("--stdout", action="store_true", help="Print instead of writing.")
    args = parser.parse_args()

    expected = build_table()
    text = render(expected)
    if json.loads(text) != expected:
        return fail("renderer produced JSON that does not round-trip")

    if args.stdout:
        sys.stdout.write(text)
        return 0

    if args.check:
        try:
            current = json.loads(ASSET_PATH.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            return fail(f"cannot read {ASSET_PATH}: {exc}")
        if current != expected:
            before, after = current.get("tzdata_version"), expected["tzdata_version"]
            if before != after:
                return fail(
                    f"tzdata changed ({before} -> {after}); run "
                    "`python3 tool/time/generate_zone_table.py` and commit the result"
                )
            return fail(
                "asset is stale; run `python3 tool/time/generate_zone_table.py` and commit the result"
            )
        print(f"Zone table is current: {ASSET_PATH} (tzdata {expected['tzdata_version']})")
        return 0

    ASSET_PATH.parent.mkdir(parents=True, exist_ok=True)
    ASSET_PATH.write_text(text, encoding="utf-8")
    zones = expected["zones"]  # type: ignore[assignment]
    count = sum(len(entry["transitions"]) for entry in zones.values())  # type: ignore[union-attr]
    print(f"Wrote {ASSET_PATH}: {len(zones)} zones, {count} rows, tzdata {expected['tzdata_version']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

