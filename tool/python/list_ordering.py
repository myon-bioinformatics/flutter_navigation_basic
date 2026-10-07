#!/usr/bin/env python3
"""Generate deterministic ordering examples for the Flutter catalogue."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

EXAMPLES: dict[str, list[Any]] = {
    "basic": [9, 2, 5, 1, 3],
    "reverse": [9, 2, 5, 1, 3],
    "multi": [
        {"group": "b", "score": 2, "name": "B2"},
        {"group": "a", "score": 1, "name": "A1"},
        {"group": "b", "score": 1, "name": "B1"},
        {"group": "a", "score": 3, "name": "A3"},
    ],
}


def order_values(mode: str, values: list[Any]) -> list[Any]:
    if mode == "basic":
        if not all(isinstance(value, (int, float)) and not isinstance(value, bool) for value in values):
            raise ValueError("basic ordering requires numbers")
        return sorted(values)
    if mode == "reverse":
        if not all(isinstance(value, (int, float)) and not isinstance(value, bool) for value in values):
            raise ValueError("reverse ordering requires numbers")
        return sorted(values, reverse=True)
    if mode == "multi":
        if not all(isinstance(value, dict) and isinstance(value.get("group"), str)
                   and isinstance(value.get("score"), (int, float))
                   and not isinstance(value.get("score"), bool) for value in values):
            raise ValueError("multi ordering requires group/score records")
        return sorted(values, key=lambda value: (value["group"], -value["score"]))
    raise ValueError("unsupported ordering mode")


def payload(mode: str) -> dict[str, Any]:
    return {"schema": "list-ordering/1", "mode": mode,
            "values": order_values(mode, EXAMPLES[mode])}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=tuple(EXAMPLES), required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv)
    text = json.dumps(payload(args.mode), ensure_ascii=False, sort_keys=True) + "\n"
    if args.check:
        try:
            current = args.output.read_text(encoding="utf-8")
        except OSError:
            return 1
        return 0 if current == text else 1
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
