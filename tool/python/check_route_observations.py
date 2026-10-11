#!/usr/bin/env python3
"""Compare observed numbered-route widgets with the hand-written expectations.

Expected: tool/ci/numbered_routes.toml (people write it).
Observed: build/route-observations.json (the Flutter observation test writes it).
Fails on any difference in count, widget kind or id. Standard library only.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys
import tomllib

ROOT = Path(__file__).resolve().parents[2]


def compare(expected: dict, observed: dict) -> list[str]:
    want = expected.get("routes", {})
    seen = observed.get("routes", {})
    if observed.get("schema") != "route-observations/1":
        return ["observations: unexpected schema"]
    problems = []
    for key in sorted(set(want) | set(seen)):
        if key not in seen:
            problems.append(f"{key}: expected {want[key]}, but no such route was observed")
        elif key not in want:
            problems.append(f"{key}: observed {seen[key]['widget']}, but it is missing from the TOML")
        elif seen[key].get("widget") != want[key] or seen[key].get("id") != int(key):
            problems.append(f"{key}: expected {want[key]}#{int(key)}, observed "
                            f"{seen[key].get('widget')}#{seen[key].get('id')}")
    if len(want) != 198:
        problems.append(f"expectations list {len(want)} routes, not 198")
    return problems


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--expected", type=Path, default=ROOT / "tool/ci/numbered_routes.toml")
    parser.add_argument("observed", type=Path)
    args = parser.parse_args(argv)
    try:
        expected = tomllib.loads(args.expected.read_text(encoding="utf-8"))
        observed = json.loads(args.observed.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        print(f"route check: cannot read input: {error}", file=sys.stderr)
        return 2
    problems = compare(expected, observed)
    annotate = os.environ.get("GITHUB_ACTIONS") == "true"
    for problem in problems:
        print("route mismatch: " + problem, file=sys.stderr)
        if annotate:  # visible on the check run without downloading logs
            print(f"::error title=route mismatch::{problem}")
    if not problems:
        print(f"routes: {len(observed['routes'])} observed, all match {args.expected.name}")
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
