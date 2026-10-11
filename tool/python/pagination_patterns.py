#!/usr/bin/env python3
"""Deterministic, stateless pagination for patterns 031/032/033 (stdlib only).

Cursor is an opaque position token scoped to an exact dataset fingerprint.
Infinite scrolling consumes successive pages; it does not imply UI scrolling.
"""
from __future__ import annotations

import base64
import hashlib
import json
import sys


def _check_int(value, name, minimum=0):
    if type(value) is not int or value < minimum:
        raise ValueError(f"{name} must be an integer >= {minimum}")
    return value


def _digest(items):
    payload = json.dumps(items, ensure_ascii=False, separators=(",", ":"), sort_keys=True,
                         allow_nan=False).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()[:24]


def _encode(index, digest):
    data = json.dumps({"v": 1, "i": index, "h": digest}, separators=(",", ":"))
    return base64.urlsafe_b64encode(data.encode()).decode().rstrip("=")


def _decode(cursor, digest):
    if not isinstance(cursor, str) or not cursor or len(cursor) > 512:
        raise ValueError("invalid cursor")
    try:
        raw = base64.b64decode(cursor + "=" * (-len(cursor) % 4), altchars=b"-_", validate=True)
        obj = json.loads(raw)
    except (ValueError, UnicodeError) as exc:
        raise ValueError("invalid cursor") from exc
    if not isinstance(obj, dict) or set(obj) != {"v", "i", "h"} or type(obj["v"]) is not int or obj["v"] != 1 or obj["h"] != digest:
        raise ValueError("cursor does not match dataset")
    return _check_int(obj["i"], "cursor index")


def page(request):
    if not isinstance(request, dict) or set(request) - {"operation", "items", "limit", "offset", "cursor"}:
        raise ValueError("invalid request fields")
    mode = request.get("operation")
    if mode not in ("offset", "cursor", "infinite"):
        raise ValueError("invalid pagination operation")
    items = request.get("items")
    if not isinstance(items, list):
        raise ValueError("items must be a list")
    limit = _check_int(request.get("limit"), "limit", 1)
    if limit > 1000:
        raise ValueError("limit too large")
    if mode == "offset":
        if "cursor" in request:
            raise ValueError("offset mode does not accept cursor")
        start = _check_int(request.get("offset", 0), "offset")
    else:
        if "offset" in request:
            raise ValueError("cursor mode does not accept offset")
        digest = _digest(items)
        start = _decode(request["cursor"], digest) if request.get("cursor") is not None else 0
    if start > len(items):
        raise ValueError("page position beyond dataset")
    end = min(start + limit, len(items))
    result = {"items": items[start:end], "has_more": end < len(items)}
    if mode == "offset":
        result["next_offset"] = end if end < len(items) else None
    else:
        result["next_cursor"] = _encode(end, digest) if end < len(items) else None
    return result


def main():
    try:
        raw = sys.stdin.read(2_000_001)
        if len(raw) > 2_000_000:
            raise ValueError("input too large")
        print(json.dumps(page(json.loads(raw)), ensure_ascii=False, allow_nan=False))
    except (ValueError, TypeError, UnicodeError) as exc:
        print(f"invalid pagination request: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
