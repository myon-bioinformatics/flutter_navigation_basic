#!/usr/bin/env python3
"""Generate deterministic text-search examples for the Flutter catalogue."""
from __future__ import annotations

import argparse
from collections import defaultdict
import json
from pathlib import Path
import re
from typing import Any

DOCUMENTS = [
    {"id": "doc-1", "text": "Flutter renders portable user interfaces"},
    {"id": "doc-2", "text": "Python processes portable data and search indexes"},
    {"id": "doc-3", "text": "Search indexes make repeated search fast"},
]
STOP_WORDS = {"and", "the", "a", "an"}
TOKEN_RE = re.compile(r"[0-9A-Za-z]+", re.ASCII)


def tokenize(text: str) -> list[str]:
    if not isinstance(text, str):
        raise TypeError("text must be a string")
    return [match.group(0).lower() for match in TOKEN_RE.finditer(text)]


def without_stop_words(tokens: list[str]) -> list[str]:
    if not all(isinstance(token, str) for token in tokens):
        raise TypeError("tokens must contain strings")
    return [token for token in tokens if token not in STOP_WORDS]


def build_inverted_index(documents: list[dict[str, str]]) -> dict[str, list[str]]:
    index: dict[str, set[str]] = defaultdict(set)
    for document in documents:
        doc_id, text = document.get("id"), document.get("text")
        if not isinstance(doc_id, str) or not doc_id or not isinstance(text, str):
            raise ValueError("documents require non-empty id and text")
        for token in without_stop_words(tokenize(text)):
            index[token].add(doc_id)
    return {token: sorted(ids) for token, ids in sorted(index.items())}


def search(documents: list[dict[str, str]], query: str) -> list[str]:
    terms = without_stop_words(tokenize(query))
    if not terms:
        return []
    index = build_inverted_index(documents)
    matches = set(index.get(terms[0], []))
    for term in terms[1:]:
        matches.intersection_update(index.get(term, []))
    return sorted(matches)


def payload(mode: str) -> dict[str, Any]:
    if mode == "search":
        values: Any = search(DOCUMENTS, "portable search")
    elif mode == "tokens":
        values = without_stop_words(tokenize("Python and Flutter search the data"))
    elif mode == "text-index":
        values = [
            {"id": document["id"], "tokens": without_stop_words(tokenize(document["text"]))}
            for document in DOCUMENTS
        ]
    elif mode == "inverted-index":
        values = [
            {"term": term, "documents": ids}
            for term, ids in build_inverted_index(DOCUMENTS).items()
        ]
    else:
        raise ValueError("unsupported text-processing mode")
    return {"schema": "text-processing/1", "mode": mode, "values": values}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("search", "tokens", "text-index", "inverted-index"), required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv)
    text = json.dumps(payload(args.mode), ensure_ascii=False, sort_keys=True) + "\n"
    if args.check:
        try:
            return 0 if args.output.read_text(encoding="utf-8") == text else 1
        except OSError:
            return 1
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
