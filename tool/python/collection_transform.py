#!/usr/bin/env python3
"""Stdlib JSON transformations for catalogue patterns 114-120.

Input contract: {"operation": "...", ...}; stdout: {"schema":"collection-transform/1",
"operation":"...", "values": ...}. CLI rejects invalid input with exit code 2.
This is real, independently callable processing, not a Flutter runtime dependency.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from collections.abc import Mapping

_MISSING = object()
_TYPES = {"null": lambda x: x is None, "boolean": lambda x: type(x) is bool,
          "integer": lambda x: type(x) is int, "number": lambda x: type(x) in (int, float),
          "string": lambda x: isinstance(x, str), "array": lambda x: isinstance(x, list),
          "object": lambda x: isinstance(x, dict)}
_OPS = {"schema_validation", "constraint", "pipeline", "map_reduce",
        "flatten", "partition", "zip"}


def _valid(condition: bool, reason: str) -> None:
    if not condition:
        raise ValueError(reason)


def _keys(obj: object, required: set[str], optional: set[str] = frozenset()) -> dict:
    _valid(isinstance(obj, dict), "expected JSON object")
    _valid(required <= obj.keys(), f"missing keys: {sorted(required - obj.keys())}")
    _valid(not (obj.keys() - required - optional), "unknown keys")
    return obj


def _type(value: object, name: object) -> bool:
    _valid(isinstance(name, str) and name in _TYPES, "invalid JSON type")
    return _TYPES[name](value)


def _schema(value: object, definition: object) -> bool:
    spec = _keys(definition, {"type"}, {"required", "properties", "items", "additional_properties"})
    if not _type(value, spec["type"]):
        return False
    if spec["type"] == "object":
        props = spec.get("properties", {})
        required = spec.get("required", [])
        additional = spec.get("additional_properties", True)
        _valid(isinstance(props, dict) and all(isinstance(k, str) for k in props), "invalid properties")
        _valid(isinstance(required, list) and all(isinstance(k, str) for k in required)
               and len(set(required)) == len(required), "invalid required")
        _valid(type(additional) is bool, "invalid additional_properties")
        for child in props.values():
            _schema_spec(child)
        if not set(required) <= value.keys():
            return False
        if not additional and set(value) - set(props):
            return False
        return all(_schema(v, props[k]) for k, v in value.items() if k in props)
    if spec["type"] == "array" and "items" in spec:
        _schema_spec(spec["items"])
        return all(_schema(v, spec["items"]) for v in value)
    _valid("properties" not in spec and "required" not in spec and
           "additional_properties" not in spec or spec["type"] == "object",
           "object options require object type")
    _valid("items" not in spec or spec["type"] == "array", "items requires array type")
    return True


def _schema_spec(spec: object) -> None:
    _valid(isinstance(spec, dict) and "type" in spec, "invalid schema definition")
    _type(None, spec["type"])
    _keys(spec, {"type"}, {"required", "properties", "items", "additional_properties"})
    if "properties" in spec:
        _valid(isinstance(spec["properties"], dict), "invalid properties")
        for child in spec["properties"].values():
            _schema_spec(child)
    if "items" in spec:
        _schema_spec(spec["items"])


def _predicate(value: object, condition: object) -> bool:
    spec = _keys(condition, {"operator"}, {"value", "type"})
    op = spec["operator"]
    _valid(op in {"equals", "not_equals", "greater_than", "less_than", "type", "not_null"},
           "unknown constraint")
    if op == "not_null":
        _valid(set(spec) == {"operator"}, "not_null accepts no operand")
        return value is not None
    if op == "type":
        _valid("type" in spec and "value" not in spec, "type requires type")
        return _type(value, spec["type"])
    _valid("value" in spec and "type" not in spec, "missing constraint value")
    other = spec["value"]
    if op in ("equals", "not_equals"):
        same = (json.dumps(value, sort_keys=True, allow_nan=False) ==
                json.dumps(other, sort_keys=True, allow_nan=False))
        return same if op == "equals" else not same
    _valid(type(value) in (int, float) and type(other) in (int, float),
           "ordered comparisons require numbers")
    return value > other if op == "greater_than" else value < other


def _pipeline(values: list, steps: object) -> list:
    _valid(isinstance(steps, list) and steps, "steps must be nonempty list")
    result = list(values)
    for spec in steps:
        step = _keys(spec, {"operation"}, {"value"})
        op = step["operation"]
        _valid(op in {"strip", "lower", "upper", "add", "multiply"}, "unsupported pipeline step")
        if op in {"strip", "lower", "upper"}:
            _valid(set(step) == {"operation"} and all(isinstance(x, str) for x in result),
                   "text step requires strings")
            result = [getattr(x, op)() for x in result]
        else:
            _valid("value" in step and type(step["value"]) in (int, float)
                   and all(type(x) in (int, float) for x in result), "numeric step requires numbers")
            result = [x + step["value"] if op == "add" else x * step["value"] for x in result]
    return result


def _flatten(values: list, depth: int = 0) -> list:
    _valid(depth <= 100, "nested arrays exceed 100 levels")
    out = []
    for value in values:
        if isinstance(value, list):
            out.extend(_flatten(value, depth + 1))
        else:
            out.append(value)
    return out


def process(payload: object) -> dict:
    obj = _keys(payload, {"operation"}, {"values", "schema", "condition", "steps",
                                         "key", "reducer", "other", "strict"})
    op = obj["operation"]
    _valid(op in _OPS, "unsupported operation")
    _valid("values" in obj and isinstance(obj["values"], list), "values must be array")
    keys = {
        "schema_validation": {"operation", "values", "schema"},
        "constraint": {"operation", "values", "condition"},
        "pipeline": {"operation", "values", "steps"},
        "map_reduce": {"operation", "values", "key", "reducer"},
        "flatten": {"operation", "values"},
        "partition": {"operation", "values", "condition"},
        "zip": {"operation", "values", "other", "strict"},
    }
    _valid(set(obj) <= keys[op], "unexpected fields for operation")
    values = obj["values"]
    if op == "schema_validation":
        _valid("schema" in obj, "schema is required")
        _schema_spec(obj["schema"])
        result = [_schema(x, obj["schema"]) for x in values]
    elif op == "constraint":
        _valid("condition" in obj, "condition is required")
        result = [_predicate(x, obj["condition"]) for x in values]
        if not values:
            _predicate(None, obj["condition"]) if obj["condition"].get("operator") in ("not_null", "type", "equals", "not_equals") else _keys(obj["condition"], {"operator", "value"})
    elif op == "pipeline":
        _valid("steps" in obj, "steps is required")
        result = _pipeline(values, obj["steps"])
    elif op == "map_reduce":
        _valid(obj.get("reducer") in ("count", "sum"), "reducer must be count or sum")
        key = obj.get("key")
        _valid(isinstance(key, str) and key, "key must be a nonempty field")
        grouped: dict[str, dict] = {}
        for x in values:
            _valid(isinstance(x, dict) and key in x, "rows must contain group key")
            value = x[key]
            _valid(type(value) in (str, int, float, bool) or value is None,
                   "group key must be scalar")
            token = json.dumps(value, sort_keys=True)
            if token not in grouped:
                grouped[token] = {"key": value, "value": 0}
            if obj["reducer"] == "sum":
                amount = x.get("value", _MISSING)
                _valid(type(amount) in (int, float), "sum rows require numeric value")
                grouped[token]["value"] += amount
            else:
                grouped[token]["value"] += 1
        result = list(grouped.values())
    elif op == "flatten":
        result = _flatten(values)
    elif op == "partition":
        _valid("condition" in obj, "condition is required")
        yes, no = [], []
        for item in values:
            (yes if _predicate(item, obj["condition"]) else no).append(item)
        result = {"matched": yes, "unmatched": no}
    else:
        other = obj.get("other")
        _valid(isinstance(other, list), "other must be array")
        strict = obj.get("strict", False)
        _valid(type(strict) is bool, "strict must be boolean")
        _valid(not strict or len(values) == len(other), "strict zip lengths differ")
        result = [[a, b] for a, b in zip(values, other)]
    return {"schema": "collection-transform/1", "operation": op, "values": result}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", default="-", help="JSON input path or - for stdin")
    args = parser.parse_args(argv)
    try:
        if args.input == "-":
            source = sys.stdin.read()
        else:
            with open(args.input, encoding="utf-8") as stream:
                source = stream.read()
        value = json.loads(source, parse_constant=lambda x: (_ for _ in ()).throw(ValueError("non-finite JSON")))
        result = process(value)
        print(json.dumps(result, ensure_ascii=False, allow_nan=False, sort_keys=True))
    except (ValueError, OSError, TypeError, RecursionError) as error:
        print(f"invalid input: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
