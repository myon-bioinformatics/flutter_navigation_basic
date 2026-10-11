#!/usr/bin/env python3
"""Pure search helpers for 006-008, 021-023 (stdlib, no UI claims).

Fuzzy matching uses normalized edit distance; stemming is an explicitly
limited English suffix heuristic, not a linguistic stemmer.
"""
from __future__ import annotations

import json
import sys
import unicodedata


def normalized(text):
    if not isinstance(text, str):
        raise ValueError("expected string")
    return unicodedata.normalize("NFKC", text).casefold()


def distance(a, b):
    row = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        nxt = [i]
        for j, cb in enumerate(b, 1):
            nxt.append(min(nxt[-1] + 1, row[j] + 1, row[j - 1] + (ca != cb)))
        row = nxt
    return row[-1]


def tokenize(text):
    import re
    return re.findall(r"\w+", normalized(text), flags=re.UNICODE)


def stem(token):
    token = normalized(token)
    if not token.isascii() or not token.isalpha():
        return token
    for suffix in ("ingly", "edly", "ing", "ed", "es", "s"):
        if token.endswith(suffix) and len(token) - len(suffix) >= 3:
            return token[:-len(suffix)]
    return token


def run(request):
    if not isinstance(request, dict):
        raise ValueError("expected request object")
    op = request.get("operation")
    if op in ("tokenize", "stem"):
        text = request.get("text")
        if not isinstance(text, str):
            raise ValueError("text required")
        tokens = tokenize(text)
        return [stem(t) for t in tokens] if op == "stem" else tokens
    if op == "history":
        events = request.get("events")
        if not isinstance(events, list) or any(not isinstance(e, str) for e in events):
            raise ValueError("events must be strings")
        limit = request.get("limit", 20)
        if type(limit) is not int or not 1 <= limit <= 1000:
            raise ValueError("invalid history limit")
        result, seen = [], set()
        for value in reversed(events):
            key = normalized(value)
            if key and key not in seen:
                result.append(value)
                seen.add(key)
                if len(result) == limit:
                    break
        return result
    if op in ("fuzzy", "autocomplete", "highlight"):
        query = normalized(request.get("query"))
        if op == "highlight":
            text = request.get("text")
            if not isinstance(text, str) or not query:
                raise ValueError("text and query required")
            # Return semantic match status, not incorrect offsets into NFKC text.
            return {"matched": query in normalized(text), "text": text}
        values = request.get("values")
        if not isinstance(values, list) or any(not isinstance(v, str) for v in values):
            raise ValueError("values must be strings")
        if not query:
            return []
        limit = request.get("limit", 10)
        if type(limit) is not int or not 1 <= limit <= 1000:
            raise ValueError("invalid result limit")
        if op == "autocomplete":
            return [v for v in values if normalized(v).startswith(query)][:limit]
        max_distance = request.get("max_distance", 2)
        if type(max_distance) is not int or not 0 <= max_distance <= 10:
            raise ValueError("invalid edit distance")
        ranked = [(distance(query, normalized(v)), i, v) for i, v in enumerate(values)]
        return [v for d, i, v in sorted(ranked) if d <= max_distance][:limit]
    raise ValueError("unsupported search operation")


def main():
    try:
        raw = sys.stdin.read(2_000_001)
        if len(raw) > 2_000_000:
            raise ValueError("input too large")
        print(json.dumps(run(json.loads(raw)), ensure_ascii=False))
    except (ValueError, TypeError) as exc:
        print(f"invalid search request: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
