#!/usr/bin/env python3
"""Filter JSON values; generate/check the same result consumed by Flutter assets.

Equality follows Python's JSON-decoded value equality. Input order and duplicates
are retained. This CLI is the sole filtering implementation; Flutter loads its
result rather than evaluating the predicate again.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Any


def filter_values(values: list[Any], *, equals: Any) -> list[Any]:
    return [value for value in values if value == equals]


def process(payload: Any) -> dict[str, list[Any]]:
    if not isinstance(payload, dict):
        raise ValueError("input must be a JSON object")
    values = payload.get("values")
    if not isinstance(values, list):
        raise ValueError("values must be a JSON list")
    if "equals" not in payload:
        raise ValueError("equals is required")
    return {"values": filter_values(values, equals=payload["equals"])}


def _reject_constant(value: str) -> None:
    raise ValueError(f"non-finite JSON constant is not supported: {value}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", default="-", help="JSON file path, or - for stdin")
    parser.add_argument("--output", type=Path, help="Write a result asset instead of stdout")
    parser.add_argument("--check", action="store_true", help="Check --output values without writing")
    args = parser.parse_args(argv)
    if args.check and args.output is None:
        parser.error("--check requires --output")
    try:
        raw = sys.stdin.read() if args.input == "-" else Path(args.input).read_text(encoding="utf-8")
        payload = json.loads(raw, parse_constant=_reject_constant)
        result = process(payload)
        rendered = json.dumps(result, ensure_ascii=False, allow_nan=False, separators=(",", ":")) + "\n"
        if args.check:
            current = json.loads(args.output.read_text(encoding="utf-8"), parse_constant=_reject_constant)
            # Compare only the consumed contract, not unrelated metadata/formatting.
            if not isinstance(current, dict) or current.get("values") != result["values"]:
                print("filter-basic: generated values are stale", file=sys.stderr)
                return 1
        elif args.output is not None:
            args.output.write_text(rendered, encoding="utf-8")
        else:
            sys.stdout.write(rendered)
    except (OSError, UnicodeError, ValueError) as error:
        print(f"filter-basic: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
