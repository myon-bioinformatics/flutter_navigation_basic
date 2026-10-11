#!/usr/bin/env python3
"""Pure JSON state transition / event reduction CLI for patterns 164–165.

No Flutter lifecycle, GetX or Redux middleware is implied.
"""
from __future__ import annotations
import argparse
import json
import sys

OPS = {"set", "increment", "decrement", "reset"}


def _integer(value: object, label: str) -> int:
    if type(value) is not int:
        raise ValueError(f"{label} must be integer")
    if abs(value) > 1_000_000_000:
        raise ValueError(f"{label} out of bounds")
    return value


def _action(state: int, raw: object, initial: int) -> int:
    if not isinstance(raw, dict) or raw.get("type") not in OPS:
        raise ValueError("action requires known type")
    op = raw["type"]
    allowed = {"type", "value"} if op in ("set", "increment", "decrement") else {"type"}
    if set(raw) != allowed:
        raise ValueError("action fields do not match type")
    if op == "reset":
        return initial
    value = _integer(raw["value"], "action value")
    result = value if op == "set" else state + value if op == "increment" else state - value
    return _integer(result, "result")


def process(payload: object) -> dict:
    if not isinstance(payload, dict) or set(payload) != {"mode", "initial", "actions"}:
        raise ValueError("expected mode, initial and actions")
    mode = payload["mode"]
    if mode not in ("event_state", "redux"):
        raise ValueError("unsupported mode")
    state = initial = _integer(payload["initial"], "initial")
    actions = payload["actions"]
    if not isinstance(actions, list) or len(actions) > 1000:
        raise ValueError("actions must be array of at most 1000")
    history = [state]
    for action in actions:
        state = _action(state, action, initial)
        history.append(state)
    return {"schema": "state-reducer/1", "mode": mode,
            "state": state, "history": history}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", default="-")
    args = parser.parse_args(argv)
    try:
        if args.input == "-":
            source = sys.stdin.read()
        else:
            with open(args.input, encoding="utf-8") as stream:
                source = stream.read()
        payload = json.loads(source, parse_constant=lambda x: (_ for _ in ()).throw(ValueError("non-finite JSON")))
        print(json.dumps(process(payload), sort_keys=True, ensure_ascii=False, allow_nan=False))
    except (ValueError, TypeError, OSError, RecursionError) as e:
        print(f"invalid input: {e}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
