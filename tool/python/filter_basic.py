#!/usr/bin/env python3
"""Filter JSON values and generate/check Flutter result assets.

Equality filters and stable distinct selection share one producer and I/O.
Flutter only displays generated results; it never evaluates predicates.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
import sys
from typing import Any

_MISSING = object()


def filter_values(values: list[Any], *, equals: Any) -> list[Any]:
    return [value for value in values if value == equals]


def distinct_values(values: list[Any]) -> list[Any]:
    """Keep first occurrences by canonical JSON; object key order is ignored.

    Boolean/integer/float encodings remain distinct, as do ordered arrays.
    Store full keys rather than only hashes so collisions cannot lose values.
    """
    seen: set[str] = set()
    result: list[Any] = []
    for value in values:
        key = json.dumps(value, sort_keys=True, ensure_ascii=False,
                         allow_nan=False, separators=(",", ":"))
        if key not in seen:
            seen.add(key)
            result.append(value)
    return result


def _at_path(value: Any, path: list[str | int]) -> Any:
    """Resolve literal object keys/list indices, never an expression or code."""
    for part in path:
        if isinstance(part, str) and isinstance(value, dict):
            value = value.get(part, _MISSING)
        elif type(part) is int and isinstance(value, list) and part < len(value):
            value = value[part]
        else:
            return _MISSING
    return value


def process(payload: Any) -> dict[str, list[Any]]:
    if not isinstance(payload, dict):
        raise ValueError("input must be a JSON object")
    values = payload.get("values")
    if not isinstance(values, list):
        raise ValueError("values must be a JSON list")
    operation = payload.get("operation", "filter")
    if operation == "distinct":
        if set(payload) - {"operation", "values"}:
            raise ValueError("distinct accepts only operation and values")
        return {"values": distinct_values(values)}
    if operation != "filter":
        raise ValueError("operation must be filter or distinct")
    if "conditions" not in payload:
        if "equals" not in payload:
            raise ValueError("equals is required")
        if "match" in payload:
            raise ValueError("match requires conditions")
        return {"values": filter_values(values, equals=payload["equals"])}
    if "equals" in payload:
        raise ValueError("use equals or conditions, not both")
    conditions = payload["conditions"]
    if not isinstance(conditions, list) or not conditions:
        raise ValueError("conditions must be a non-empty list")
    match = payload.get("match", "all")
    if match not in ("all", "any"):
        raise ValueError("match must be all or any")
    # Validate every condition before filtering, even with no input values.
    for condition in conditions:
        if (not isinstance(condition, dict) or "equals" not in condition or
                set(condition) - {"path", "equals"}):
            raise ValueError("each condition accepts only path and required equals")
        path = condition.get("path", [])
        if not isinstance(path, list) or any(
            not (isinstance(part, str) or (type(part) is int and part >= 0))
            for part in path
        ):
            raise ValueError("path must contain literal keys or non-negative integer indices")
    combine = all if match == "all" else any
    def matches(value: Any, condition: dict[str, Any]) -> bool:
        found = _at_path(value, condition.get("path", []))
        return found is not _MISSING and found == condition["equals"]
    return {"values": [value for value in values if combine(
        matches(value, condition) for condition in conditions
    )]}


def _reject_constant(value: str) -> None:
    raise ValueError(f"non-finite JSON constant is not supported: {value}")


def _finite_float(value: str) -> float:
    # parse_constant rejects NaN/Infinity, but not an overflowing exponent.
    number = float(value)
    if not math.isfinite(number):
        raise ValueError("non-finite JSON number is not supported")
    return number


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
        payload = json.loads(raw, parse_constant=_reject_constant, parse_float=_finite_float)
        result = process(payload)
        rendered = json.dumps(result, ensure_ascii=False, allow_nan=False, separators=(",", ":")) + "\n"
        if args.check:
            current = json.loads(args.output.read_text(encoding="utf-8"), parse_constant=_reject_constant, parse_float=_finite_float)
            # Compare only the consumed contract, not unrelated metadata/formatting.
            if (not isinstance(current, dict) or "values" not in current or
                    json.dumps(current["values"], sort_keys=True) !=
                    json.dumps(result["values"], sort_keys=True)):
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
