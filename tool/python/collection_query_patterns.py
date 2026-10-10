#!/usr/bin/env python3
"""Pure collection operations for patterns 011, 012, 014-018 (stdlib)."""
from __future__ import annotations
import json
import math
import sys


def run(req):
    if not isinstance(req, dict) or not isinstance(req.get("items"), list):
        raise ValueError("items must be a list")
    items = req["items"]
    op = req.get("operation")
    if op in ("stable_sort", "custom_sort"):
        key = req.get("key")
        if not isinstance(key, str) or not key:
            raise ValueError("sort key required")
        if any(not isinstance(row, dict) or key not in row for row in items):
            raise ValueError("missing sort key")
        values = [row[key] for row in items]
        if any(type(v) not in (str, int, float) or
               (type(v) is float and not math.isfinite(v)) for v in values):
            raise ValueError("unsupported sort key")
        if len({type(v) for v in values}) > 1:
            raise ValueError("mixed sort key types")
        descending = req.get("descending", False)
        if type(descending) is not bool:
            raise ValueError("descending must be boolean")
        if op == "custom_sort":
            # A named comparator, not executable input or arbitrary eval.
            comparator = req.get("comparator")
            if comparator not in ("ascending", "descending"):
                raise ValueError("unsupported comparator")
            descending = comparator == "descending"
        return sorted(items, key=lambda row: row[key], reverse=descending)
    if op == "group_by":
        key = req.get("key")
        if not isinstance(key, str) or not key:
            raise ValueError("group key required")
        groups = []
        for item in items:
            if not isinstance(item, dict) or key not in item:
                raise ValueError("missing group key")
            value = item[key]
            if type(value) not in (str, int, float, bool, type(None)):
                raise ValueError("group key must be scalar")
            group = next((g for g in groups if type(g["value"]) is type(value)
                          and g["value"] == value), None)
            if group is None:
                group = {"value": value, "items": []}
                groups.append(group)
            group["items"].append(item)
        return groups
    if op in ("facet", "tag"):
        key = req.get("key")
        selected = req.get("selected")
        if not isinstance(key, str) or not isinstance(selected, list):
            raise ValueError("key and selected list required")
        if any(type(v) not in (str, int, float, bool) for v in selected):
            raise ValueError("invalid selected value")
        def matches(item):
            if not isinstance(item, dict) or key not in item:
                raise ValueError("missing filter key")
            value = item[key]
            if op == "tag":
                if not isinstance(value, list):
                    raise ValueError("tags must be a list")
                return any(tag in value for tag in selected)
            return value in selected
        return [item for item in items if matches(item)]
    if op == "range":
        key, low, high = req.get("key"), req.get("minimum"), req.get("maximum")
        if not isinstance(key, str) or any(type(v) not in (int, float) or not math.isfinite(v)
                                           for v in (low, high)) or low > high:
            raise ValueError("invalid numeric range")
        result = []
        for item in items:
            if not isinstance(item, dict) or key not in item:
                raise ValueError("missing range key")
            v = item[key]
            if type(v) not in (int, float) or not math.isfinite(v):
                raise ValueError("invalid range value")
            if low <= v <= high:
                result.append(item)
        return result
    if op == "geo":
        lat, lon, radius = (req.get(k) for k in ("latitude", "longitude", "radius_km"))
        if any(type(v) not in (int, float) or not math.isfinite(v)
               for v in (lat, lon, radius)) or not (-90 <= lat <= 90 and -180 <= lon <= 180 and radius >= 0):
            raise ValueError("invalid geographic search")
        def distance(row):
            if not isinstance(row, dict):
                raise ValueError("invalid point")
            a, b = row.get("latitude"), row.get("longitude")
            if any(type(v) not in (int, float) or not math.isfinite(v) for v in (a, b)) or not (-90 <= a <= 90 and -180 <= b <= 180):
                raise ValueError("invalid point coordinates")
            p1, p2 = math.radians(lat), math.radians(a)
            dp, dl = p2-p1, math.radians(b-lon)
            h = math.sin(dp/2)**2 + math.cos(p1)*math.cos(p2)*math.sin(dl/2)**2
            return 6371.0088 * 2 * math.asin(min(1, math.sqrt(h)))
        return [row for row in items if distance(row) <= radius]
    raise ValueError("unsupported operation")


def main():
    try:
        data = sys.stdin.read(2_000_001)
        if len(data) > 2_000_000:
            raise ValueError("input too large")
        print(json.dumps(run(json.loads(data)), ensure_ascii=False, allow_nan=False))
    except (ValueError, TypeError) as exc:
        print(f"invalid collection request: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
