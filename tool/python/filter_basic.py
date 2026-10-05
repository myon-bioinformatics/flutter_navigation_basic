#!/usr/bin/env python3
"""Filter a JSON list using a small stdlib-only predicate contract."""

from __future__ import annotations

import argparse
import json
import sys
from typing import Any


def filter_values(values: list[Any], *, equals: Any) -> list[Any]:
    return [value for value in values if value == equals]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", default="-", help="JSON file path, or - for stdin")
    args = parser.parse_args(argv)
    try:
        raw = sys.stdin.read() if args.input == "-" else open(args.input, encoding="utf-8").read()
        payload = json.loads(raw)
        if not isinstance(payload, dict):
            raise ValueError("input must be a JSON object")
        values = payload.get("values")
        if not isinstance(values, list):
            raise ValueError("values must be a JSON list")
        if "equals" not in payload:
            raise ValueError("equals is required")
        result = {"values": filter_values(values, equals=payload["equals"])}
    except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as error:
        print(f"filter-basic: {error}", file=sys.stderr)
        return 2
    json.dump(result, sys.stdout, ensure_ascii=False, separators=(",", ":"))
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
