#!/usr/bin/env python3
"""Audit generated pattern services for obvious placeholder implementations."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

MARKERS = (
    "TODO: 実装を追加してください",
    "await Future.delayed(const Duration(milliseconds: 100));",
    "executed successfully",
)
FAMILIES = (
    "api_patterns",
    "data_processing_patterns",
    "navigation_patterns",
    "ui_theme_patterns",
)


def audit(root: Path) -> dict[str, object]:
    result: dict[str, object] = {}
    skipped_undecodable: list[str] = []
    scanned_by_family: dict[str, int] = {}
    features = root / "lib" / "features"
    if not features.is_dir():
        raise ValueError(f"missing pattern root: {features}")
    missing = [family for family in FAMILIES if not (features / family).is_dir()]
    if missing:
        raise ValueError("missing pattern families: " + ", ".join(missing))
    for family in FAMILIES:
        placeholders: list[str] = []
        base = features / family
        services = sorted(base.rglob("service.dart"))
        scanned_by_family[family] = len(services)
        for service in services:
            try:
                content = service.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                skipped_undecodable.append(service.relative_to(root).as_posix())
                continue
            if all(marker in content for marker in MARKERS):
                placeholders.append(service.relative_to(root).as_posix())
        result[family] = placeholders
    result["_summary"] = {
        "placeholder_total": sum(len(result[family]) for family in FAMILIES),
        "scanned_service_total": sum(scanned_by_family.values()),
        "scanned_service_by_family": scanned_by_family,
        "skipped_undecodable": skipped_undecodable,
        "skipped_undecodable_count": len(skipped_undecodable),
    }
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
    )
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    try:
        result = audit(args.root.resolve())
    except (OSError, ValueError) as error:
        print(f"pattern-stub-audit: {error}", file=sys.stderr)
        return 2
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        for family in FAMILIES:
            paths = result[family]
            print(f"{family}: {len(paths)} placeholder service(s)")
            for path in paths:
                print(f"  {path}")
        summary = result["_summary"]
        print(f"total: {summary['placeholder_total']} placeholder service(s)")
        print(f"scanned services: {summary['scanned_service_total']}")
        print(f"skipped undecodable: {summary['skipped_undecodable_count']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
