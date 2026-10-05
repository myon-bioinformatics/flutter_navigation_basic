#!/usr/bin/env python3
"""Audit generated pattern services for obvious placeholder implementations.

Stdlib-only by design so it can run in constrained CI and locally without
installing project dependencies.
"""

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


def audit(root: Path) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    features = root / "lib" / "features"
    for family in FAMILIES:
        paths: list[str] = []
        base = features / family
        if not base.is_dir():
            continue
        for service in sorted(base.rglob("service.dart")):
            text = service.read_text(encoding="utf-8")
            if all(marker in text for marker in MARKERS):
                paths.append(service.relative_to(root).as_posix())
        result[family] = paths
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    args = parser.parse_args()

    result = audit(args.root.resolve())
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        for family in FAMILIES:
            paths = result.get(family, [])
            print(f"{family}: {len(paths)} placeholder service(s)")
            for path in paths:
                print(f"  {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
