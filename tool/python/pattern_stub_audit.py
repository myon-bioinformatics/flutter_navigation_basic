#!/usr/bin/env python3
"""Audit generated pattern services for obvious placeholder implementations."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

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
    features = root / "lib" / "features"
    for family in FAMILIES:
        placeholders: list[str] = []
        base = features / family
        if base.is_dir():
            for service in sorted(base.rglob("service.dart")):
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
    result = audit(args.root.resolve())
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
        print(f"skipped undecodable: {summary['skipped_undecodable_count']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
