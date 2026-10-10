#!/usr/bin/env python3
"""Pure TF-IDF and minimum-heap contracts for patterns 025 and 028."""
from __future__ import annotations
from collections import Counter
import heapq
import json
import math
import re
import sys


def tfidf(documents):
    if not isinstance(documents, list) or any(not isinstance(d, str) for d in documents):
        raise ValueError("documents must be strings")
    tokens = [re.findall(r"\w+", d.casefold()) for d in documents]
    count = len(tokens)
    df = Counter(word for doc in tokens for word in set(doc))
    return [{word: (freq / len(doc)) * (math.log((count + 1) / (df[word] + 1)) + 1)
             for word, freq in sorted(Counter(doc).items())} for doc in tokens]


def minheap(values, pops):
    if not isinstance(values, list) or any(type(x) not in (int, float) or
       not math.isfinite(x) for x in values):
        raise ValueError("heap values must be finite numbers")
    if type(pops) is not int or not 0 <= pops <= len(values):
        raise ValueError("invalid pop count")
    heap = values.copy()
    heapq.heapify(heap)
    removed = [heapq.heappop(heap) for _ in range(pops)]
    return {"popped": removed, "remaining_sorted": sorted(heap)}


def run(payload):
    if not isinstance(payload, dict):
        raise ValueError("request must be object")
    operation = payload.get("operation")
    if operation == "tfidf":
        if set(payload) != {"operation", "documents"}:
            raise ValueError("unexpected TF-IDF fields")
        return tfidf(payload["documents"])
    if operation == "minheap":
        if set(payload) - {"operation", "values", "pops"}:
            raise ValueError("unexpected heap fields")
        return minheap(payload.get("values"), payload.get("pops", 0))
    raise ValueError("unsupported operation")


def main():
    try:
        raw = sys.stdin.read(2_000_001)
        if len(raw) > 2_000_000:
            raise ValueError("input too large")
        print(json.dumps(run(json.loads(raw)), ensure_ascii=False, allow_nan=False))
    except (ValueError, TypeError, KeyError) as error:
        print(f"invalid request: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
