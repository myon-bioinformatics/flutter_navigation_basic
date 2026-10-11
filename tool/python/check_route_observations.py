#!/usr/bin/env python3
"""Compare observed numbered-route widgets with the hand-written expectations.

Expected: tool/ci/numbered_routes.toml (people write it).
Observed: build/test-results/route-observations.json (the Flutter observation test writes it).
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


def compare(expected: dict, observed: dict, *, head_sha: str | None = None, run_id: str | None = None) -> list[str]:
    want = expected.get("routes", {})
    seen = observed.get("routes", {})
    if observed.get("schema") != "route-observations/2":
        return ["observations: unexpected schema"]
    provenance = observed.get("provenance")
    if not isinstance(provenance, dict):
        return ["observations: missing provenance"]
    if head_sha is not None and provenance.get("head_sha") != head_sha:
        return [f"observations: head SHA {provenance.get('head_sha')!r} != expected {head_sha!r}"]
    if run_id is not None and provenance.get("run_id") != run_id:
        return [f"observations: run ID {provenance.get('run_id')!r} != expected {run_id!r}"]
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
    parser.add_argument("--head-sha")
    parser.add_argument("--run-id")
    parser.add_argument("--receipt", type=Path)
    args = parser.parse_args(argv)
    try:
        expected = tomllib.loads(args.expected.read_text(encoding="utf-8"))
        observed = json.loads(args.observed.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        print(f"route check: cannot read input: {error}", file=sys.stderr)
        return 2
    problems = compare(expected, observed, head_sha=args.head_sha, run_id=args.run_id)
    annotate = os.environ.get("GITHUB_ACTIONS") == "true"
    for problem in problems:
        print("route mismatch: " + problem, file=sys.stderr)
        if annotate:  # visible on the check run without downloading logs
            print(f"::error title=route mismatch::{problem}")
    if not problems:
        print(f"routes: {len(observed['routes'])} observed, all match {args.expected.name}")
        if args.receipt:
            receipt = {
                "schema": "route-verification/1",
                "head_sha": observed["provenance"]["head_sha"],
                "run_id": observed["provenance"]["run_id"],
                "routes": len(observed["routes"]),
                "expected": args.expected.as_posix(),
                "observed": args.observed.as_posix(),
                "result": "success",
            }
            args.receipt.parent.mkdir(parents=True, exist_ok=True)
            args.receipt.write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
